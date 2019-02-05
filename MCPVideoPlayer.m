//
//  VideoPlayer.m
//  Smokescreen
//
//  Created by Alfred Hanssen on 2/9/14.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MCPVideoPlayer.h"

static const float DefaultPlayableBufferLength = 2.0f;
static const float DefaultVolumeFadeDuration = 1.0f;
static const float TimeObserverInterval = 0.01f;

static NSString * const kVideoPlayerErrorDomain = @"kVideoPlayerErrorDomain";
static const NSKeyValueObservingOptions MCPObservingBaseOptions = NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld;

@interface MCPVideoPlayer ()
//! Propiedad que nos dirá si se esta buscando un segundo concreto del vídeo o no
@property (nonatomic, assign) BOOL isSeeking;
//! Propiedad que indicará si debemos buscar un segundo concreto cuando el video este disponible. Esta propiedad solo será seteada si se ha intentado buscar un segundo concreto pero el item del player aun no esta preparado para reproducirse.
@property (nonatomic, assign) CGFloat seekTimeWhenAvailable;
//! Propiedad que nos dirá cuan largo necesita un buffer para ser reproducible
@property (nonatomic, assign) float playableBufferLength;
//! Token que contendrá el observer para el tiempo trascurrido viendo en el video. Este es el observer que informará sobre los segundos que se ha visto sobre el video en el player.
@property (nonatomic, strong) id timeObserverToken;
//! Asset que será reproducido al dar al play.
@property (nonatomic, strong) AVAsset *assetToReproduce;
//! Esta propiedad nos dirá si hemos cargado ya o no el primer pedazo del buffer del vídeo
@property (nonatomic, assign) BOOL isFirstChunckBufferLoaded;
@end

@implementation MCPVideoPlayer

- (void)dealloc
{
    [self resetPlayerItemIfNecessary];
    [self disableTimeUpdates];
    [self cancelFadeVolume];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _playableBufferLength = DefaultPlayableBufferLength;
        
        [self setupPlayer];
        [self setupAudioSession];
        [self enableTimeUpdates];
    }
    
    return self;
}

#pragma mark - Setup

- (void)setupPlayer
{
    _player = [[AVPlayer alloc] init];
    _player.muted = NO;
    _player.allowsExternalPlayback = YES;
}

- (void)setupAudioSession
{
    NSError *categoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&categoryError];
    if (!success)
        NSLog(@"Error setting audio session category: %@", categoryError);
    
    NSError *activeError = nil;
    success = [[AVAudioSession sharedInstance] setActive:YES error:&activeError];
    if (!success)
        NSLog(@"Error setting audio session active: %@", activeError);
}

#pragma mark - Check methods

- (BOOL)isAtEndTime
{
    if (self.player && self.player.currentItem){
        
        float currentTime = 0.0f;
        if (!CMTIME_IS_INVALID(self.player.currentTime))
            currentTime = CMTimeGetSeconds(self.player.currentTime);
        
        float videoDuration = 0.0f;
        if (!CMTIME_IS_INVALID(self.player.currentItem.duration))
            videoDuration = CMTimeGetSeconds(self.player.currentItem.duration);
        
        if (currentTime > 0.0f && videoDuration > 0.0f){
            if (fabs(currentTime - videoDuration) <= 0.01f)
                return YES;
        }
    }
    
    return NO;
}

#pragma mark - Time Updates

- (void)enableTimeUpdates
{
    if (self.timeObserverToken || self.player == nil) return;
    
    __weak typeof (self) weakSelf = self;
    self.timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(TimeObserverInterval, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        __strong typeof (self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(videoPlayer:currentTimeDidChange:)])
            [strongSelf.delegate videoPlayer:strongSelf currentTimeDidChange:time];
    }];
}

- (void)disableTimeUpdates
{
    if (self.timeObserverToken == nil) return;
    
    if (self.player)
        [self.player removeTimeObserver:self.timeObserverToken];
    
    self.timeObserverToken = nil;
}

#pragma mark - Prepare player item methods

- (void)setURL:(NSURL *)URL
{
    if (!URL) return;

    [self setAsset:[AVAsset assetWithURL:URL]];
}

- (void)setAsset:(AVAsset *)asset
{
    if (!asset) return;
    
    // Nos guardamos el asset a reproducir al pulsar play (Esto lo hacemos por si es un video en Streaming, dado que no queremos empezar a cargarlo hasta que el usuario pulse play)
    self.assetToReproduce = asset;
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    if (!playerItem){
        [self reportUnableToCreatePlayerItem];
        return;
    }
    
    [self resetPlayerItemIfNecessary];
    [self preparePlayerItem:playerItem];
}

/**
 *  Método que prepara el PlayerItem con el asset anteriormente seteado para ser reproducido. Este método da un error mediante el delegado tanto si no se ha podido crear el Player, como si el
 *  Asset no estaba establecido al llegar a este método. 
 *
 *  @note Es responsabilidad del player el manejo de los errores si se produjesen al intentar preparar el player
 *
 *  @return YES si todo ha funcionado correctamente, NO de lo contrario.
 */
-(BOOL)preparePlayerItemWithCurrentAsset{
    
    if(!self.assetToReproduce){
        [self reportUnableToCreatePlayerItem];
        return NO;
    }
    
    [self resetPlayerItemIfNecessary];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:self.assetToReproduce];
    if (!playerItem)
    {
        [self reportUnableToCreatePlayerItem];
        return NO;
    }
    
    [self preparePlayerItem:playerItem];
    return YES;
}

#pragma mark - Playback

- (void)play
{
    // Si aún no tenemos item, preparamos el item con el asset que tenemos
    if (!self.player.currentItem){
        BOOL prepareSuccesful = [self preparePlayerItemWithCurrentAsset];
        if(!prepareSuccesful){
            return;
        }
    }
   
    _playing = YES;
    _stopped = NO;  
    
    if ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay){
        [self.player play];
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerIsAboutToPlay:asset:)])
            [self.delegate videoPlayerIsAboutToPlay:self asset:self.assetToReproduce];
    }
}

- (void)pause
{
    _playing = NO;
    [self.player pause];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerHasBeenPaused:asset:)])
        [self.delegate videoPlayerHasBeenPaused:self asset:self.assetToReproduce];
}

-(void)stop{
    _playing = NO;
    _stopped = YES;
    [self pause];
    [self seekToTime:0];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerHasStopped:asset:)])
        [self.delegate videoPlayerHasStopped:self asset:self.assetToReproduce];
}

- (void)seekToTime:(CGFloat)time
{
    if (self.isSeeking || !self.player) return;
    
    CMTime cmTime = CMTimeMakeWithSeconds(time, self.player.currentTime.timescale);
    
    
    if (CMTIME_IS_INVALID(cmTime) || self.player.currentItem.status != AVPlayerStatusReadyToPlay){
        self.seekTimeWhenAvailable = time;
        return;
    }
    
    self.seekTimeWhenAvailable = 0;
    self.isSeeking = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.player seekToTime:cmTime completionHandler:^(BOOL finished) {
            self.isSeeking = NO;
        }];
    });
}

-(void)forwardVideoWithNumberOfSeconds:(NSInteger)seconds{
    NSInteger currentSecond = (NSInteger)lroundf(self.player.currentTime.value/self.player.currentTime.timescale);
    NSInteger forwardSecond = currentSecond + seconds;
    [self seekToTime:forwardSecond];
}

-(void)rewindVideoWithNumberOfSeconds:(NSInteger)seconds{
    NSInteger currentSecond = (NSInteger)lroundf(self.player.currentTime.value/self.player.currentTime.timescale);
    NSInteger rewindSecond = currentSecond - seconds;
    [self seekToTime:rewindSecond];
}

#pragma mark - Volume

- (void)setVolume:(float)volume
{
    [self cancelFadeVolume];
    
    self.player.volume = volume;
}

- (void)cancelFadeVolume
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeInVolume) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutVolume) object:nil];
}

- (void)fadeInVolume
{
    if (!self.player) return;
    
    [self cancelFadeVolume];
    
    if (self.player.volume >= 1.0f - 0.01f){
        self.player.volume = 1.0f;
    }else{
        self.player.volume += 1.0f/10.0f;
        [self performSelector:@selector(fadeInVolume) withObject:nil afterDelay:DefaultVolumeFadeDuration/10.0f];
    }
}

- (void)fadeOutVolume
{
    if (!self.player) return;
    
    [self cancelFadeVolume];
    
    if (self.player.volume <= 0.01f){
        self.player.volume = 0.0f;
    }else{
        self.player.volume -= 1.0f/10.0f;
        [self performSelector:@selector(fadeOutVolume) withObject:nil afterDelay:DefaultVolumeFadeDuration/10.0f];
    }
}

#pragma mark - Private API

- (void)reportUnableToCreatePlayerItem
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:didFailWithError:)])
    {
        NSError *error = [NSError errorWithDomain:kVideoPlayerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to create AVPlayerItem."}];
        [self.delegate videoPlayer:self didFailWithError:error];
    }
}

- (void)resetPlayerItemIfNecessary
{
    if (self.player.currentItem)
    {
        [self removePlayerItemObservers];
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    
    _playableBufferLength = DefaultPlayableBufferLength;
    _playing = NO;
    self.isFirstChunckBufferLoaded = NO;
}

- (void)preparePlayerItem:(AVPlayerItem *)playerItem
{
    NSParameterAssert(playerItem);
    
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self addPlayerItemObservers];
}


- (float)calcLoadedDuration
{
    float loadedDuration = 0.0f;
    
    if (self.player && self.player.currentItem)
    {
        NSArray *loadedTimeRanges = self.player.currentItem.loadedTimeRanges;
        if (loadedTimeRanges && [loadedTimeRanges count])
        {
            CMTimeRange timeRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            
            loadedDuration = startSeconds + durationSeconds;
        }
    }
    
    return loadedDuration;
}

#pragma mark - PlayerItem Observers

- (void)addPlayerItemObservers
{
    [self.player.currentItem addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:MCPObservingBaseOptions | NSKeyValueObservingOptionOld context:nil];
    [self.player.currentItem addObserver:self forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp)) options:MCPObservingBaseOptions context:nil];
    [self.player.currentItem addObserver:self forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges)) options:MCPObservingBaseOptions context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)removePlayerItemObservers
{
    [self.player.currentItem cancelPendingSeeks];

    [self.player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status)) context:nil];
    [self.player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp)) context:nil];
    [self.player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges)) context:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

#pragma mark - NSNotification Methods

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification
{
    if (notification.object != self.player.currentItem) return;

    [self stop];
    
    if (self.isLooping)
        [self play];
}

#pragma mark - Observer methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:NSStringFromSelector(@selector(status))]){
        [self handlePlayerStatusUpdate];
    }else if ([keyPath isEqualToString:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))]){
        [self handleUpdatedBufferToKeepUp];
    } else if (NSStringFromSelector(@selector(loadedTimeRanges))){
        [self handleBufferLengthChange];
    }
}

#pragma mark - Update methods

//! Método llamado cuando se obtenga un cambio en el estado del player
-(void)handlePlayerStatusUpdate{
    
    switch (self.player.currentItem.status)
    {
        case AVPlayerItemStatusReadyToPlay:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerIsReadyToPlayVideo:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate videoPlayerIsReadyToPlayVideo:self];
                });
            }
            
            if(self.bufferDelegate && [self.bufferDelegate respondsToSelector:@selector(videoPlayer:totalVideoDurationReceived:)])
                [self.bufferDelegate videoPlayer:self totalVideoDurationReceived:self.player.currentItem.duration];
            
            if(self.seekTimeWhenAvailable)
                [self seekToTime:self.seekTimeWhenAvailable];
            
            if (self.isPlaying)
                [self play];
            break;
        }
        case AVPlayerItemStatusFailed:{
            NSLog(@"Video player Status Failed: player item error = %@", self.player.currentItem.error);
            NSLog(@"Video player Status Failed: player error = %@", self.player.error);
            
            NSError *error = self.player.error ? self.player.error : self.player.currentItem.error;
            if (!error)
                error = [NSError errorWithDomain:kVideoPlayerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"unknown player error, status == AVPlayerItemStatusFailed"}];
            
            [self pause];
            [self resetPlayerItemIfNecessary];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:didFailWithError:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate videoPlayer:self didFailWithError:error];
                });
            }
            
            break;
        }
        case AVPlayerItemStatusUnknown:
        default:{
            NSLog(@"Video player Status Unknown");
            break;
        }
    }
}

//! Método llamado cuando se tenga el suficiente buffer para continuar la reproducción al haberse quedado sin buffer reproduciendo un vídeo
-(void)handleUpdatedBufferToKeepUp{
    if (!self.player.currentItem.playbackLikelyToKeepUp) return;

    if (self.isPlaying && self.player.rate == 0.0f)
        [self play];
}

//! Método llamado cuando cambie la longitud del buffer obtenido
-(void)handleBufferLengthChange{
    CGFloat loadedDuration = [self calcLoadedDuration];
    
    // Avisamos en el primer pedazo de buffer recibido, al delegado
    if(!self.isFirstChunckBufferLoaded){
        if(self.bufferDelegate && [self.bufferDelegate respondsToSelector:@selector(videoPlayerHasStartedLoadingBuffer:)])
            [self.bufferDelegate videoPlayerHasStartedLoadingBuffer:self];
        self.isFirstChunckBufferLoaded = YES;
    }
    
    if (self.isPlaying && self.player.rate == 0.0f)
    {
        if (loadedDuration >= CMTimeGetSeconds(self.player.currentTime) + self.playableBufferLength)
        {
            self.playableBufferLength *= 2;
            
            if (self.playableBufferLength > 64)
                self.playableBufferLength = 64;
            
            [self play];
        }
    }
    
    if (self.bufferDelegate && [self.bufferDelegate respondsToSelector:@selector(videoPlayer:loadedBufferDurationRangeDidChange:)])
        [self.bufferDelegate videoPlayer:self loadedBufferDurationRangeDidChange:loadedDuration];
}

#pragma mark - Setter methods

- (void)setMuted:(BOOL)muted
{
    if (self.player)
        self.player.muted = muted;
}

- (BOOL)isMuted
{
    return self.player.isMuted;
}

@end

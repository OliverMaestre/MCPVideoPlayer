//
//  VideoPlayerView.m
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

#import "MCPVideoPlayerView.h"
#import "MCPVideoPlayer.h"

#import "MCPFullScreenHandler.h"

#import "NSString+MCPFormat.h"

#import <AVFoundation/AVFoundation.h>

@interface MCPVideoPlayerView () <MCPVideoPlayerDelegate, MCPVideoPlayerBufferDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, assign) BOOL bottomBarIsShown;
//! Propiedad que guardará el color de fondo de la vista cuando esta pausada
@property (nonatomic, strong) UIColor *stoppedBackgroundColor;
@end

@implementation MCPVideoPlayerView

- (void)dealloc
{
    [self detachPlayer];
    self.tapRecognizer.delegate = nil;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    
    [self loadPlayer];
    [self configureViewsForStopState];
}

#pragma mark - Load methods

- (void)loadPlayer
{
    // Inicialización de variables
    _player = [[MCPVideoPlayer alloc] init];
    _player.looping = self.makeVideoLoop;
    
    self.sliderProgress.minimumValue = 0;
    self.sliderProgress.maximumValue = 100;
    self.sliderProgress.value = 0;
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(makeSwitchBottomBarVisibilityAnimation)];
    [self.tapRecognizer setNumberOfTapsRequired:1];
    [self.tapRecognizer setEnabled:YES];
    [self.tapRecognizer setDelegate:self];
    [self addGestureRecognizer:self.tapRecognizer];
    
    if(!self.hideBarsAfterPlayDelay)
        self.hideBarsAfterPlayDelay = kDefaultHideBarsDelay;
    if(!self.forwardSeconds)
        self.forwardSeconds = kDefaultForwardSeconds;
    if(!self.rewindSeconds)
        self.rewindSeconds = kDefaultRewindSeconds;
    if(!self.nonStoppedStatusBackgroundColor)
        self.nonStoppedStatusBackgroundColor = [UIColor blackColor];
    
    self.stoppedBackgroundColor = self.backgroundColor;
    
    self.bottomBarIsShown = YES;
    
    [self attachPlayer];
}

#pragma mark - Update Views methods

-(void)configureViewsForStopState{
    self.controlsContainer.hidden = NO;
    self.btnBigPlay.hidden = NO;
    self.bottomBar.hidden = YES;
    self.spinner.hidden = YES;
    self.customSpinner.hidden = YES;
    self.txtErrorLoad.hidden = YES;
    
    self.tapRecognizer.enabled = NO;
    self.backgroundColor = self.stoppedBackgroundColor;
}

-(void)configureViewsForLoadingState{
    self.controlsContainer.hidden = YES;
    self.btnBigPlay.hidden = YES;
    self.bottomBar.hidden = YES;
    self.spinner.hidden = NO;
    self.customSpinner.hidden = NO;
    self.txtErrorLoad.hidden = YES;
    
    self.tapRecognizer.enabled = NO;
    self.backgroundColor = self.nonStoppedStatusBackgroundColor;
}

-(void)configureViewsForPlayingState{
    self.controlsContainer.hidden = NO;
    self.btnBigPlay.hidden = YES;
    self.bottomBar.hidden = NO;
    self.spinner.hidden = YES;
    self.customSpinner.hidden = YES;
    self.txtErrorLoad.hidden = YES;
    
    self.tapRecognizer.enabled = YES;
    self.backgroundColor = self.nonStoppedStatusBackgroundColor;
}

-(void)configureViewsForErrorState{
    self.controlsContainer.hidden = YES;
    self.btnBigPlay.hidden = YES;
    self.bottomBar.hidden = YES;
    self.spinner.hidden = YES;
    self.customSpinner.hidden = YES;
    self.txtErrorLoad.hidden = NO;
    
    self.tapRecognizer.enabled = YES;
    self.backgroundColor = self.nonStoppedStatusBackgroundColor;
}

-(void)makeSwitchBottomBarVisibilityAnimation{
    
    // Eliminamos todas las posibles animaciones que se pudieron hacer o las que puedan venir detrás para evitar parpadeos
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(makeSwitchBottomBarVisibilityAnimation) object:nil];
    [self.bottomBar.layer removeAllAnimations];
    
    // Obtenemos la información sobre el switch
    BOOL finallyShown = !self.bottomBarIsShown;
    CGFloat finalAlpha = finallyShown ? 1.f : .0f;
    
    // Animamos la barra
    [UIView animateWithDuration:.3f animations:^{
        self.bottomBar.alpha = finalAlpha;
    }completion:^(BOOL finished) {
        self.bottomBarIsShown = finallyShown;
    }];
}

#pragma mark - Public API

- (void)setPlayer:(MCPVideoPlayer *)player
{
    if (_player == player) return;

    [self detachPlayer];
    _player = player;
    [self attachPlayer];
}

#pragma mark - Player methods

- (void)attachPlayer
{
    if(!self.player) return;
    
    self.player.delegate = self;
    self.player.bufferDelegate = self;
}

- (void)detachPlayer
{
    if (self.player && self.player.delegate == self)
        self.player.delegate = nil;
    if (self.player && self.player.bufferDelegate == self)
        self.player.bufferDelegate = nil;
}

+(Class)layerClass{
    return [AVPlayerLayer class];
}

/**
 *  Método que añade o quita el player a la vista actual. Para que el player funcione con el comportamiento esperado (De colores de fondo etc...) este método debe ser llamado tanto en
 *  cada stop realizado en el video como en cada play.
 *
 *  @param add YES para añadir el video al layer de este reproductor, NO para quitarlo.
 */
-(void)addPlayerOnView:(BOOL)add{
    AVPlayer *playerToAdd = nil;
    if(add)
        playerToAdd = self.player.player;
    
    [(AVPlayerLayer *)[self layer] setPlayer:playerToAdd];
}

#pragma mark - IBAction's

-(IBAction)playTapped{
    if(self.player.isPlaying){ // Pause
        [self.player pause];
    }else{                     // Play
        [self.player play];
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerViewHasStartedReproducingVideo:)])
        [self.delegate videoPlayerViewHasStartedReproducingVideo:self];
}

-(IBAction)stopTapped{
    [self.player stop];
    [self.btnPlay setSelected:NO];
    [self configureViewsForStopState];
}

-(IBAction)forwardTapped{
    [self.player forwardVideoWithNumberOfSeconds:self.forwardSeconds];
}

-(IBAction)rewindTapped{
    [self.player rewindVideoWithNumberOfSeconds:self.rewindSeconds];
}

-(IBAction)fullScreenTapped{
    
    [[MCPFullScreenHandler sharedhandler] handleFullScreenWithCaller:self];
}

-(IBAction)sliderChanged{
    // Video information
    CMTime videoTime = self.player.player.currentItem.duration;
    NSInteger totalVideoSeconds = (NSInteger)lroundf(videoTime.value/videoTime.timescale);
    
    // Slider information
    CGFloat sliderPropotion = (self.sliderProgress.value*(self.sliderProgress.maximumValue-self.sliderProgress.minimumValue))/10000;
    
    // Results and update
    CGFloat finalSecond = sliderPropotion * totalVideoSeconds;
    [self.player seekToTime:finalSecond];
}

#pragma mark - MCPVideoPlayerDelegate methods

-(void)videoPlayerIsAboutToPlay:(MCPVideoPlayer *)videoPlayer asset:(AVAsset *)asset{
    [self configureViewsForPlayingState];
    [self addPlayerOnView:YES];
    
    
    [self.btnPlay setSelected:YES];
    if(self.hideBarsOnPlay)
        [self performSelector:@selector(makeSwitchBottomBarVisibilityAnimation) withObject:nil afterDelay:self.hideBarsAfterPlayDelay];
}

-(void)videoPlayerHasBeenPaused:(MCPVideoPlayer *)videoPlayer asset:(AVAsset *)asset{
    [self.btnPlay setSelected:NO];
    if(self.hideBarsOnStop)
        [self performSelector:@selector(makeSwitchBottomBarVisibilityAnimation) withObject:nil afterDelay:self.hideBarsAfterPlayDelay];
}

- (void)videoPlayerIsReadyToPlayVideo:(MCPVideoPlayer *)videoPlayer
{
    [self configureViewsForPlayingState];
    
    [self.customSpinner stopAnimating];
    [self.spinner stopAnimating];
}

- (void)videoPlayerHasStopped:(MCPVideoPlayer *)videoPlayer
{
    [self configureViewsForStopState];
    [self addPlayerOnView:NO];
    
    // Avisamos al delegado
    if ([self.delegate respondsToSelector:@selector(videoPlayerViewDidReachEnd:)])
        [self.delegate videoPlayerViewDidReachEnd:self];
}

- (void)videoPlayer:(MCPVideoPlayer *)videoPlayer didFailWithError:(NSError *)error
{
    [self configureViewsForErrorState];
}

#pragma mark - MCPVideoPlayerBufferDelegate methods

-(void)videoPlayerHasStartedLoadingBuffer:(MCPVideoPlayer *)videoPlayer{
    [self configureViewsForLoadingState];
    
    [self.customSpinner startAnimating];
    [self.spinner startAnimating];
}

-(void)videoPlayer:(MCPVideoPlayer *)videoPlayer totalVideoDurationReceived:(CMTime)totalVideoTime{
    // Seteamos el tiempo total del video en el label
    self.lblVideoTime.text = [NSString mcp_getTimeFormattedStringWithSeconds:(NSInteger)lroundf(totalVideoTime.value/totalVideoTime.timescale)];
}

- (void)videoPlayer:(MCPVideoPlayer *)videoPlayer currentTimeDidChange:(CMTime)cmTime
{
    NSInteger currentSecond = (NSInteger)lroundf(cmTime.value/cmTime.timescale);
    
    // Seteamos el texto del segundo actual
    self.lblCurrentTime.text = [NSString mcp_getTimeFormattedStringWithSeconds:currentSecond];
    
    // Cambiamos el slider proporcionalmente
    CMTime videoTime = self.player.player.currentItem.duration;
    NSInteger totalVideoSeconds = (NSInteger)lroundf(videoTime.value/videoTime.timescale);
    NSInteger currentTimeProportion = (currentSecond*100)/totalVideoSeconds;
    
    self.sliderProgress.value = currentTimeProportion;
}

#pragma mark - UIGestureRecognizerDelegate methods

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    // Si hemos la barra inferior o una de sus subvistas, no manejamos el touch
    if([touch.view isDescendantOfView:self.bottomBar] || touch.view == self.bottomBar)
        return NO;
    return YES;
}

@end

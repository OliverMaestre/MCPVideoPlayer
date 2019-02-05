//
//  VideoPlayer.h
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "MCPVideoPlayerDelegate.h"
#import "MCPVideoPlayerBufferDelegate.h"

@interface MCPVideoPlayer : NSObject

@property (nonatomic, weak) id<MCPVideoPlayerDelegate> delegate;
@property (nonatomic, weak) id<MCPVideoPlayerBufferDelegate> bufferDelegate;

@property (nonatomic, strong, readonly) AVPlayer *player;

//! Booleana que nos dirá si el player esta reproduciendo algun vídeo. Si esta variable y la variable Stopped están a NO, significa que el vídeo esta pausado.
@property (nonatomic, assign, getter=isPlaying, readonly) BOOL playing;
//! Booleana que nos dirá si el player no esta reproduciendo ningún vídeo. Si esta variable y la variable Stopped están a NO, significa que el vídeo esta pausado.
@property (nonatomic, assign, getter=isStopped, readonly) BOOL stopped;
//! Booleana que nos dirá si el player tiene orden de reproducir infinitamente el vídeo. Si se reproduce infinitamente y el vídeo llega al final, se llamará al método stop y luego a play para seguir con el bucle, con sus consecuentes llamadas a los métodos delegados.
@property (nonatomic, assign, getter=isLooping) BOOL looping;
//! Booleana que nos dirá si el player tiene o no sonido.
@property (nonatomic, assign, getter=isMuted) BOOL muted;

#pragma mark - Source methods

- (void)setURL:(NSURL *)URL;
- (void)setPlayerItem:(AVPlayerItem *)playerItem;
- (void)setAsset:(AVAsset *)asset;

#pragma mark - Play methods

/**
 *  Método que arranca el video y lo reproduce desde el segundo en el que se encuentre
 */
- (void)play;
/**
 *  Método que hace pause del video y lo deja parado en el segundo en el que estaba
 */
- (void)pause;
/**
 *  Método que para el vídeo y lo deja como en su estado inicial
 */
- (void)stop;

/**
 *  Método para buscar un tiempo determinado en el vídeo. Este método se encarga de la conversión del tiempo (Pasado en segundos) a lo correpsondiente en el video.
 *
 *  @note Si el player ya se encuentra buscando un segundo concreto, este método no hará nada
 *
 *  @param time Segundo al que se quiere ir en el timeline del video.
 */
- (void)seekToTime:(CGFloat)time;

/**
 *  Método que adelanta el vídeo el número de segundos especificado. 
 *
 *  @note Si el player ya se encuentra buscando un segundo concreto, este método no hará nada
 *
 *  @param seconds Valor con tantos segundos como se quiera adelantar el vídeo
 */
-(void)forwardVideoWithNumberOfSeconds:(NSInteger)seconds;

/**
 *  Método que atrasa el vídeo el número de segundos especificado
 *
 *  @note Si el player ya se encuentra buscando un segundo concreto, este método no hará nada
 *
 *  @param seconds Valor con tantos segundos como se quiera retrasar el vídeo
 */
-(void)rewindVideoWithNumberOfSeconds:(NSInteger)seconds;


#pragma mark - Time Update methods

- (void)enableTimeUpdates;
- (void)disableTimeUpdates;

#pragma mark - Volume methods

- (void)setVolume:(float)volume;
- (void)fadeInVolume;
- (void)fadeOutVolume;

@end

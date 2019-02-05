//
//  VideoPlayerView.h
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

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "MCPVideoPlayer.h"

#import "MCPAnimatingViewProtocol.h"

@class MCPVideoPlayerView;

@protocol MCPVideoPlayerViewDelegate <NSObject>

@optional
- (void)videoPlayerViewHasStartedReproducingVideo:(MCPVideoPlayerView *)videoPlayerView;
- (void)videoPlayerViewDidReachEnd:(MCPVideoPlayerView *)videoPlayerView;
@end

static const NSInteger kDefaultHideBarsDelay = 4.f;
static const NSInteger kDefaultForwardSeconds = 5.f;
static const NSInteger kDefaultRewindSeconds = 5.f;

@interface MCPVideoPlayerView : UIView

@property (nonatomic, weak) id<MCPVideoPlayerViewDelegate> delegate;
@property (nonatomic, strong) MCPVideoPlayer *player;

#pragma mark - IBInspectable configurations

//! Esta propiedad contendrá el color a establecer de fondo del player cuando este esté en un estado distinto a stop.
@property (nonatomic, strong) IBInspectable UIColor *nonStoppedStatusBackgroundColor;
//! Esta propiedad establece el número de segundos a esperar antes de ocultar las barras del player tras haber pulsado el botón play/pause o algún otro.
@property (nonatomic, assign) IBInspectable NSInteger hideBarsAfterPlayDelay;
//! Esta propiedad establece el número de segundos a esperar antes de ocultar las barras del player tras haber pulsado el botón play/pause o algún otro.
@property (nonatomic, assign) IBInspectable NSInteger forwardSeconds;
//! Esta propiedad establece el número de segundos a esperar antes de ocultar las barras del player tras haber pulsado el botón play/pause o algún otro.
@property (nonatomic, assign) IBInspectable NSInteger rewindSeconds;
//! Esta propiedad dirá si el video debe o no reproducirse en bucle
@property (nonatomic, assign) IBInspectable BOOL makeVideoLoop;
//! Esta propiedad dirá si las barras deben ocultarse automáticamente al pulsar play
@property (nonatomic, assign) IBInspectable BOOL hideBarsOnPlay;
//! Esta propiedad dirá si las barras deben ocultarse automáticamente al pulsar stop/pause
@property (nonatomic, assign) IBInspectable BOOL hideBarsOnStop;
//! Esta propiedad establecerá el nombre del nib a cargar para cuando se pulse el botón de pantalla completa.
@property (nonatomic, strong) IBInspectable NSString *fullScreenNibName;
//! Esta propiedad dirá como debe mostrarse el fullScreen del player. Sus valores son los de el tipo UIInterfaceOrientation.
@property (nonatomic, assign) IBInspectable NSInteger fullScreenOrientation;

#pragma mark - IBOutlets

//! Vista contenedora que debe tener todos los controles a mostrar/ocultar dependiendo de si ha habido o no algún error al cargar el video. Esta vista debe contener las barras de arriba y abajo etc...
@property (nonatomic, weak) IBOutlet UIView *controlsContainer;
//! Vista contenedora de los controles de la barra inferior del player. Aqui suele ir el slider, además de los botones de control del video
@property (nonatomic, weak) IBOutlet UIView *bottomBar;
//! Botón de play. Normalmente añadido a alguna de las barras del player. Este botón a su vez es también el botón Pause. Una vez play es pulsado, este botón pasa a estar marcado como selected, cuando se vuelve a pulsar, estará unselected. Las imagenes deben estar puestas correspondientemente a los estados nombrados si se quiere cambiar las imágenes dependiendo de si el video se esta o no reproduciendo.
@property (nonatomic, weak) IBOutlet UIButton *btnPlay;
//! Botón de play grande, establecido fuera de las barras y que aparece antes de que el video haya comenzado
@property (nonatomic, weak) IBOutlet UIButton *btnBigPlay;
//! Botón de adelantar.
@property (nonatomic, weak) IBOutlet UIButton *btnForward;
//! Botón de rebobinar.
@property (nonatomic, weak) IBOutlet UIButton *btnRewind;
//! Botón de Stop
@property (nonatomic, weak) IBOutlet UIButton *btnStop;
//! Botón de pantalla completa
@property (nonatomic, weak) IBOutlet UIButton *btnFullScreen;
//! Slider de progreso del vídeo donde se puede adelantar o retrasar el vídeo. Este slider siempre tendrá valores de 0 a 100. Además al cargar esta vista y dependiendo del video, su valor se irá actualizando.
@property (nonatomic, weak) IBOutlet UISlider *sliderProgress;
//! Label que contendrá el tiempo total del vídeo.
@property (nonatomic, weak) IBOutlet UILabel *lblVideoTime;
//! Label que contendrá la posición actual del vídeo
@property (nonatomic, weak) IBOutlet UILabel *lblCurrentTime;
//! Label que se mostrará si ocurrió algún error en la carga del video.
@property (nonatomic, weak) IBOutlet UILabel *txtErrorLoad;
//! Spinner de actividad de carga nativo.
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;
//! Spinner de actividad de carga customizado.
@property (nonatomic, weak) IBOutlet UIView<MCPAnimatingViewProtocol> *customSpinner;

@end

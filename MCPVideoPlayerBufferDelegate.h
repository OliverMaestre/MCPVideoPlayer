//
//  MCPVideoPlayerBufferDelegate.h
//  Pods
//
//  Created by Mario Chinchilla PlanetMedia on 24/11/15.
//
//

@class MCPVideoPlayer;

@protocol MCPVideoPlayerBufferDelegate <NSObject>

@optional

/**
 *  Método llamado cuando el player ha empezado la carga del buffer. Cuando este sea suficiente para la reproducción del video se llamará al método 'videoPlayerIsReadyToPlayVideo:'.
 *  Este método puede servir para comenzar la animación de spinners de carga.
 *
 *  @param videoPlayer Player responsable del vídeo
 */
-(void)videoPlayerHasStartedLoadingBuffer:(MCPVideoPlayer *)videoPlayer;

/**
 *  Método llamado cuando se ha cargado más parte del buffer del vídeo.
 *
 *  @param videoPlayer Player responsable del vídeo
 *  @param duration    Segundos obtenidos en el buffer.
 */
- (void)videoPlayer:(MCPVideoPlayer *)videoPlayer loadedBufferDurationRangeDidChange:(float)duration;

/**
 *  Método llamado cuando se ha recibido el tiempo total del vídeo.
 *
 *  @param videoPlayer    Player responsable del vídeo
 *  @param totalVideoTime Tiempo total del vídeo, independientemente del buffer.
 */
- (void)videoPlayer:(MCPVideoPlayer *)videoPlayer totalVideoDurationReceived:(CMTime)totalVideoTime;

@end

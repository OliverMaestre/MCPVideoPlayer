//
//  MCPVideoPlayerDelegate.h
//  Pods
//
//  Created by Mario Chinchilla on 24/11/15.
//
//

@class MCPVideoPlayer;

@protocol MCPVideoPlayerDelegate <NSObject>

@optional

/**
 *  Método llamado cuando el player esta listo para reproducir el vídeo porque ya tiene el buffer mínimo necesario para ello. Este método puede servir para quitar los spinners de carga que 
 *  pudiese haber en el reproductor.
 *
 *  @note Tener en cuenta que este método puede ser llamado solamente una vez dado que si no hay ningún fallo, el estado del player solo se actualizará una vez.
 *
 *  @param videoPlayer Player responable del vídeo
 */
- (void)videoPlayerIsReadyToPlayVideo:(MCPVideoPlayer *)videoPlayer;

/**
 *  Método llamado cuando el vídeo ha finalizado de forma natural o se ha pulsado Stop.
 *
 *  @param videoPlayer Player responsable del vídeo
 */
- (void)videoPlayerHasStopped:(MCPVideoPlayer *)videoPlayer asset:(AVAsset*)asset;

/**
 *  Método llamado cuando el reproductor de vídeo ha pausado la reproducción del video que tiene en su asset.
 *
 *  @param videoPlayer Player responsable del video
 *  @param asset       Asset que se ha pausado
 */
- (void)videoPlayerHasBeenPaused:(MCPVideoPlayer *)videoPlayer asset:(AVAsset*)asset;

/**
 *  Método llamado cuando el reproductor de vídeo va a comenzar la reproducción del vídeo que tiene en su asset.
 *
 *  @note Aunque este método sea llamado, puede que la reproducción del video no comience inmediatamente (E.j Por la carga de un buffer en un video por streaming).
 *
 *  @param videoPlayer Player responsable del video
 *  @param Asset que va a ser reproducido por el player
 */
- (void)videoPlayerIsAboutToPlay:(MCPVideoPlayer *)videoPlayer asset:(AVAsset*)asset;

/**
 *  Método llamado cuando ha fallado la carga del vídeo en el player. Esto puede deberse a un fallo en el propio vídeo o a que el player no ha podido cargar el video por motivos internos.
 *
 *  @param videoPlayer Player responsable del vídeo
 *  @param error       Error producido y que no permitió la reproducción del video
 */
- (void)videoPlayer:(MCPVideoPlayer *)videoPlayer didFailWithError:(NSError *)error;

/**
 *  Método llamado a cada segundo cuando el vídeo se esta reproduciendo y que devuelve el tiempo actual en el que nos encontramos en el video.
 *
 *  @param videoPlayer Player responsable del vídeo
 *  @param cmTime      Tiempo en el que nos encontramos en el vídeo
 */
- (void)videoPlayer:(MCPVideoPlayer *)videoPlayer currentTimeDidChange:(CMTime)cmTime;

@end

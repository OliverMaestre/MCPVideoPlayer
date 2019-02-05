//
//  MCPFullScreenHandler.m
//  Pods
//
//  Created by Mario Chinchilla PlanetMedia on 25/11/15.
//
//

#import "MCPFullScreenHandler.h"

#import "MCPVideoPlayerView.h"

#import "PureLayout.h"

#import "NSString+MCPValidations.h"
#import "UIView+MCPLoad.h"

@interface MCPFullScreenHandler()
//! Player que será rellenado y mostrado cuando sea oportuno
@property (nonatomic, strong) MCPVideoPlayerView *fullScreenPlayer;
//! Player que invocó al fullScreen player y que debe ser notificado cuando este último haya hecho algun cambio en el video
@property (nonatomic, weak) MCPVideoPlayerView *fullScreenSummoner;
@end

@implementation MCPFullScreenHandler

+ (id)sharedhandler{
    static MCPFullScreenHandler *sharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHandler = [[self alloc]init];
    });
    return sharedHandler;
}

#pragma mark - Full Screen methods

-(void)handleFullScreenWithCaller:(MCPVideoPlayerView*)playerView{
    
    if(!self.isShowingFullScreen){
        if([NSString mcp_isEmptyOrNilString:playerView.fullScreenNibName]) return;
        
        MCPVideoPlayerView *fullPlayerView = [MCPVideoPlayerView mcp_makeViewWithNibName:playerView.fullScreenNibName];
        if(fullPlayerView){
            // Guardamos los players
            self.fullScreenPlayer = fullPlayerView;
            self.fullScreenSummoner = playerView;
            
            // Preparamos y mostramos la pantalla completa
            [self updateVideoStatusOnPlayer:self.fullScreenPlayer withPlayer:self.fullScreenSummoner];
            [self showFullScreenPlayer];
        }
    }else{
        [self updateVideoStatusOnPlayer:self.fullScreenSummoner withPlayer:self.fullScreenPlayer];
        [self hideFullScreenPlayer];
        
        self.fullScreenSummoner = nil;
    }
}

#pragma mark - Update methods

-(void)updateVideoStatusOnPlayer:(MCPVideoPlayerView*)playerToUpdate withPlayer:(MCPVideoPlayerView*)updatedPlayer{
    
    // Obtenemos si el player actualizado estaba o no reproduciendo el vídeo
    BOOL updatedPlayerWasPlaying = [updatedPlayer.player isPlaying];
    
    // Pausamos el player actualizado
    [updatedPlayer.player pause];
    
    // Obtenemos la info del player que ha invocado la pantalla completa
    CMTime currentVideoTime = [updatedPlayer.player.player currentTime];
    
    // Configuramos y mostramos el nuevo player a pantalla completa
    [playerToUpdate.player setPlayerItem:[updatedPlayer.player.player.currentItem copy]];
    [playerToUpdate.player seekToTime:currentVideoTime.value/currentVideoTime.timescale];
    if(updatedPlayerWasPlaying)
        [playerToUpdate.player play];
}

#pragma mark - Show Full Screen methods

-(void)showFullScreenPlayer{
    
    /**** Obtenemos la información necesaria para mostrar el fullScreenPlayer ****/
    UIInterfaceOrientation orientation = self.fullScreenSummoner.fullScreenOrientation;
    
    /**** Obtenemos el controller actualmente mostrado ****/
    UINavigationController *rootController = (UINavigationController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    UIViewController *topViewController = nil;
    if(![rootController isKindOfClass:[UINavigationController class]])
        topViewController = rootController.navigationController.topViewController;
    else
        topViewController = rootController.topViewController;
    
    if(!topViewController){
        self.fullScreenSummoner = nil;
        self.fullScreenPlayer = nil;
        return; // Si no hemos encontrado ningun topViewController, salimos del método y borramos todo
    }

    /**** Guardamos el player y lo añadimos a la vista del controller obtenido ****/
    [topViewController.view addSubview:self.fullScreenPlayer];
    _isShowingFullScreen = YES;
    
    /**** Giramos el player si corresponde y ponemos el player a pantalla completa ****/
    if(UIInterfaceOrientationIsLandscape(orientation)){
        CGSize originalSize = self.fullScreenPlayer.frame.size;
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
        if(orientation == UIInterfaceOrientationLandscapeLeft)
            rotationTransform = CGAffineTransformMakeRotation(-M_PI_2);
            
        self.fullScreenPlayer.transform = rotationTransform;
        [self.fullScreenPlayer setNeedsLayout];
        [self.fullScreenPlayer autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.fullScreenPlayer autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.fullScreenPlayer autoSetDimensionsToSize:originalSize];
    }
}

#pragma mark - Hide Full Screen methods

-(void)hideFullScreenPlayer{
    
    [self.fullScreenPlayer removeFromSuperview];
    self.fullScreenPlayer = nil;
    
    _isShowingFullScreen = NO;
}

@end

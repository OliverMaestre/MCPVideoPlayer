//
//  MCPFullScreenHandler.h
//  Pods
//
//  Created by Mario Chinchilla PlanetMedia on 25/11/15.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class MCPVideoPlayerView;

@interface MCPFullScreenHandler : NSObject

//! Booleana que nos dirá si la pantalla completa se está mostrando actualmente o no
@property (nonatomic, assign, readonly) BOOL isShowingFullScreen;

+ (id)sharedhandler;

-(void)handleFullScreenWithCaller:(MCPVideoPlayerView*)playerView;

@end

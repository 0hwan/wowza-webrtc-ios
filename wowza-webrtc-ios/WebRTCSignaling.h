//
//  WebRTCSignaling.h
//  wowza-webrtc-ios
//
//

#ifndef WebRTCSignaling_h
#define WebRTCSignaling_h

#import <Foundation/Foundation.h>
#import <SocketRocket.h>

typedef NS_ENUM(NSInteger, WebRTCSignalingState) {
    // State when disconnected.
    kARDWebSocketChannelStateClosed,
    // State when connection is established but not ready for use.
    kARDWebSocketChannelStateOpen,
    // State when connection is established and registered.
    kARDWebSocketChannelStateRegistered,
    // State when connection encounters a fatal error.
    kARDWebSocketChannelStateError
};

@class WebRTCSignaling;

@protocol WebRTCSignalingDelegate <NSObject>

- (void)socketChannel:(WebRTCSignaling *)socketChannel webSocketDidOpen:(NSString *)message;
- (void)socketChannel:(WebRTCSignaling *)socketChannel didReceiveMessage:(NSDictionary *)data;
- (void)socketChannel:(WebRTCSignaling *)socketChannel didChangeState:(WebRTCSignalingState)state;
- (void)socketChannel:(WebRTCSignaling *)socketChannel sendEventMessage:(NSString *)message;

@end

@interface WebRTCSignaling : NSObject

@property(nonatomic,weak) id<WebRTCSignalingDelegate> delegate;

- (instancetype)initWithURL:(NSString *)url delegate:(id<WebRTCSignalingDelegate>)delegate;
//- (void)connect;
//- (void)disconnect;
- (void)sendMessage:(NSDictionary *)message;
@end
#endif /* WebRTCSignaling_h */


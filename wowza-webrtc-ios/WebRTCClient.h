//
//  WebRTCClient.h
//  wowza-webrtc-ios
//
//

#ifndef WebRTCClient_h
#define WebRTCClient_h

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

#import "WebRTCPeer.h"

@class WebRTCClient;

@protocol WebRTCClientDelegate <NSObject>

- (void)client:(WebRTCClient *)client didReceiveLocalVideo:(WebRTCPeer *)peer;
- (void)client:(WebRTCClient *)client didRemoveLocalVideo:(WebRTCPeer *)peer;
- (void)client:(WebRTCClient *)client didReceiveRemoteVideo:(WebRTCPeer *)peer;
- (void)client:(WebRTCClient *)client didRemoveRemoteVideo:(WebRTCPeer *)peer;


@end

@interface WebRTCClient : NSObject

@property(nonatomic, weak) id<WebRTCClientDelegate> delegate;
@property(nonatomic, strong) RTCMediaStream *localMediaStream;
@property(nonatomic, strong) NSMutableDictionary *remotePeers;
@property(nonatomic, strong) WebRTCPeer *localPeer;

- (instancetype)initWithDelegate:(id<WebRTCClientDelegate>)delegate;
- (void)initLocalMedia;
- (void)removeLocalMedia;
@end


#endif /* WebRTCClient_h */

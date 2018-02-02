//
//  WebRTCPeer.h
//  wowza-webrtc-ios
//
//  Created by 안영환 on 2018. 2. 1..
//

#ifndef WebRTCPeer_h
#define WebRTCPeer_h

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

@protocol WebRTCRemotePeerDelegate <NSObject>

@end

@interface WebRTCPeer : NSObject

@property(nonatomic)  NSString *applicationName;
@property(nonatomic)  NSString *streamName;
@property(nonatomic)  NSString *sessionID;

@property(nonatomic, weak) id<WebRTCRemotePeerDelegate> delegate;

@property(nonatomic,strong) RTCPeerConnection *peerConnection;
@property(nonatomic,strong) RTCEAGLVideoView *view;
@property(nonatomic,strong) RTCRtpSender *audioRender;
@property(nonatomic,strong) RTCRtpSender *videoRender;
@property(nonatomic,strong) RTCMediaStream *localStream;
@property(nonatomic,readonly) RTCMediaStream *remoteStream;

- (instancetype)initWithDelegate:(id<WebRTCRemotePeerDelegate>)delegate;
- (void)setRemoteSDP:(RTCSessionDescription *)sdp block:(void (^)(NSError* error))block;
- (void)offerWithConstraints:(RTCMediaConstraints*)constraints Block:(void (^)(RTCSessionDescription* sdp, NSError* error))block;
- (void)answerWithConstraints:(RTCMediaConstraints*)constraints Block:(void (^)(RTCSessionDescription* sdp, NSError* error))block;
- (void)addCandidate:(RTCIceCandidate *)candidate;

@end

#endif /* WebRTCPeer_h */

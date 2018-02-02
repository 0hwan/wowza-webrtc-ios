//
//  WebRTCPeer.h
//  wowza-webrtc-ios
//
//

#ifndef WebRTCPeer_h
#define WebRTCPeer_h

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

@class WebRTCPeer;

@protocol WebRTCPeerDelegate <NSObject>

-(void)peer:(WebRTCPeer*)peer didReceiveRemoteVideo:(RTCVideoTrack*)track;
-(void)peer:(WebRTCPeer*)peer didRemoveRemoteVideo:(RTCVideoTrack*)track;
-(void)peer:(WebRTCPeer*)peer didOccurError:(NSInteger*)errorCode;
-(void)peer:(WebRTCPeer*)peer didGotCandidate:(RTCIceCandidate*)candidate;
-(void)sendMessage:(NSDictionary*)message;

@end

@interface WebRTCPeer : NSObject

@property(nonatomic)  NSString *sessionID;
@property(nonatomic)  NSString *applicationName;
@property(nonatomic)  NSString *streamName;

@property(nonatomic,weak)id<WebRTCPeerDelegate> delegate;
@property(nonatomic,strong) RTCPeerConnection *peerConnection;
@property(nonatomic,strong) RTCEAGLVideoView *view;
@property(nonatomic,strong) RTCRtpSender *audioRender;
@property(nonatomic,strong) RTCRtpSender *videoRender;
@property(nonatomic,strong) RTCMediaStream *localStream;
@property(nonatomic,readonly) RTCMediaStream *remoteStream;

- (instancetype)initWithDelegate:(id<WebRTCPeerDelegate>)delegate;
- (void)offerWithConstraints:(RTCMediaConstraints*)constraints Block:(void (^)(RTCSessionDescription* sdp, NSError* error))block;
- (void)answerWithConstraints:(RTCMediaConstraints*)constraints Block:(void (^)(RTCSessionDescription* sdp, NSError* error))block;
- (void)setRemoteSDP:(RTCSessionDescription*)sdp block:(void (^)(NSError* error))block;
- (void)addCandidate:(RTCIceCandidate*)candidate;
- (void)leave;

@end




#endif /* WebRTCPeer_h */

//
//  WebRTCPeer.m
//  wowza-webrtc-ios
//
//

#import "WebRTCPeer.h"
#import <WebRTC/RTCEAGLVideoView.h>

@interface WebRTCPeer () <RTCPeerConnectionDelegate, RTCEAGLVideoViewDelegate> {
    RTCVideoTrack *_visibleVideoTrack;
}
@end

@implementation WebRTCPeer

- (instancetype)initWithDelegate:(id<WebRTCPeerDelegate>)delegate {
    self = [super init];
    _delegate = delegate;
    _view = [[RTCEAGLVideoView alloc] init];
    _view.delegate = self;
    return self;
}

- (void)offerWithConstraints:(RTCMediaConstraints *)constraints Block:(void (^)(RTCSessionDescription *, NSError *))block {
    [_peerConnection offerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        //we can handle more sdp info here
        NSLog(@"WebRTCPeer::offerWithConstraints::completionHandler");
        block(sdp,error);
    }];
    
//    [self setMaxBitrateForPeerConnectionVideoSender];
}


- (void)addCandidate:(RTCIceCandidate *)candidate {
    NSLog(@"WebRTCPeer::addCandidate");
    [_peerConnection addIceCandidate:candidate];
}

- (void)answerWithConstraints:(RTCMediaConstraints *)constraints Block:(void (^)(RTCSessionDescription *, NSError *))block {
    NSLog(@"WebRTCPeer::answerWithConstraints");
    [_peerConnection answerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        NSLog(@"WebRTCPeer::answerWithConstraints::completionHandler");

        block(sdp,error);
    }];
}

- (void)setRemoteSDP:(RTCSessionDescription *)sdp block:(void (^)(NSError *))block {
    NSLog(@"WebRTCPeer::setRemoteSDP");

    [_peerConnection setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
        NSLog(@"WebRTCPeer::setRemoteDescription::completionHandler");
        block(error);
    }];
}

- (void)leave {
    NSLog(@"WebRTCPeer::leave streamName[%@]", _streamName);
 
    [_peerConnection close];
}

#pragma mark - RTCPeerConnectionDelegate

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didAddStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"WebRTCPeer::peerConnection didAddStream");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"WebRTCPeer::peerConnection didAddStream Received %lu video tracks and %lu audio tracks",
               (unsigned long)stream.videoTracks.count,
               (unsigned long)stream.audioTracks.count);
        if (stream.videoTracks.count) {
            _visibleVideoTrack = stream.videoTracks[0];
            [_delegate peer:self didReceiveRemoteVideo:_visibleVideoTrack];

        }
    });
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState");
    switch (newState) {
        case RTCIceConnectionStateNew:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateNew]");
            break;
            
        case RTCIceConnectionStateChecking:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateChecking]");
            break;
            
        case RTCIceConnectionStateConnected:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateConnected]");
            break;
            
        case RTCIceConnectionStateCompleted:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateCompleted]");
            break;
            
        case RTCIceConnectionStateFailed:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateFailed]");
            break;
            
        case RTCIceConnectionStateDisconnected:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateDisconnected]");
            break;
            
        case RTCIceConnectionStateClosed:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateClosed]");
            break;
            
        case RTCIceConnectionStateCount:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [RTCIceConnectionStateCount]");
            break;
            
        default:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceConnectionState [default]");
            break;
    }
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    NSLog(@"WebRTCPeer::peerConnection didChangeIceGatheringState");
    
    switch (newState) {
        case RTCIceGatheringStateNew:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceGatheringState [RTCIceGatheringStateNew]");
            break;
            
        case RTCIceGatheringStateGathering:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceGatheringState [RTCIceGatheringStateGathering]");
            break;
            
        case RTCIceGatheringStateComplete:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceGatheringState [RTCIceGatheringStateComplete]");
            break;
            
        default:
            NSLog(@"WebRTCPeer::peerConnection didChangeIceGatheringState [default]");
            break;
    }
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState");
    
    switch (stateChanged) {
        case RTCSignalingStateStable:
            NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState [RTCSignalingStateStable]");
            break;
            
        case RTCSignalingStateHaveLocalOffer:
            NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState [RTCSignalingStateHaveLocalOffer]");
            break;
            
        case RTCSignalingStateHaveLocalPrAnswer:
            NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState [RTCSignalingStateHaveLocalPrAnswer]");
            break;
            
        case RTCSignalingStateHaveRemoteOffer:
            NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState [RTCSignalingStateHaveRemoteOffer]");
            break;
            
        case RTCSignalingStateHaveRemotePrAnswer:
            NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState [RTCSignalingStateHaveRemotePrAnswer]");
            break;
    
        case RTCSignalingStateClosed:
            NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState [default]");
            break;
            
        default:
            NSLog(@"WebRTCPeer::peerConnection didChangeSignalingState [default]");
            break;
    }
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didGenerateIceCandidate:(nonnull RTCIceCandidate *)candidate {
    NSLog(@"WebRTCPeer::peerConnection didGenerateIceCandidate [%@]", candidate);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didOpenDataChannel:(nonnull RTCDataChannel *)dataChannel {
    NSLog(@"WebRTCPeer::peerConnection didOpenDataChannel [%@]", dataChannel);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"WebRTCPeer::peerConnection didRemoveIceCandidates [%@]", candidates);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"WebRTCPeer::peerConnection didRemoveStream");
    if ([_delegate respondsToSelector:@selector(peer:didRemoveRemoteVideo:)]) {
        
        if ([stream.videoTracks count] > 0) {
            [_delegate peer:self didRemoveRemoteVideo:stream.videoTracks[0]];
        }
    }
}

- (void)peerConnectionShouldNegotiate:(nonnull RTCPeerConnection *)peerConnection {
    NSLog(@"WebRTCPeer::peerConnectionShouldNegotiate peerConnection");
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(nonnull RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    NSLog(@"WebRTCPeer::videoView didChangeVideoSize width[%f] height[%f]", size.width, size.height);
}

@end

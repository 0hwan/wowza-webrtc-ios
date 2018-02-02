//
//  WebRTCClient.m
//  wowza-webrtc-ios
//
//

#import "WebRTCClient.h"
#import "WebRTCSignaling.h"
#import "WebRTCPeer.h"

static NSString *kWowzaAppName = @"webrtc";
static NSString *kStreamName = @"example";
NSString *kWowzaServerURL = @"ws://localhost.streamlock.net/webrtc-session.json";

@interface WebRTCClient () <WebRTCSignalingDelegate, WebRTCPeerDelegate> {
    RTCMediaConstraints *_mediaConstraints;
    RTCPeerConnectionFactory *_peerConnectionFactory;
    
    RTCAudioTrack*  _localAudioTrack;
    RTCVideoTrack*  _localVideoTrack;
    
    WebRTCSignaling *_webRtcSignal;
    NSString *_applicationName;
    NSString *_streamName;
}

@end

@implementation WebRTCClient

- (instancetype)initWithDelegate:(id<WebRTCClientDelegate>)delegate {
    NSLog(@"WebRTCClient::initWithDelegate");
    self = [super init];
    _delegate = delegate;
    _applicationName = kWowzaAppName;
    _streamName = kStreamName;
    
    _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    _webRtcSignal = [[WebRTCSignaling alloc] initWithURL:kWowzaServerURL delegate:self];
    _remotePeers = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)initLocalMedia {
    NSLog(@"WebRTCClient::initLocalMedia");
    _localPeer = [[WebRTCPeer alloc] initWithDelegate:self];
    
    if (!self.localMediaStream) {
        _localMediaStream = [_peerConnectionFactory mediaStreamWithStreamId:_streamName];
    }
    
    if (_localAudioTrack == nil) {
        NSLog(@"WebRTCClient::initLocalMedia::addAudioTrack");
        _localAudioTrack = [_peerConnectionFactory audioTrackWithTrackId:@"Auido"];
        [_localMediaStream addAudioTrack:_localAudioTrack];
    }
    
    if (_localVideoTrack == nil) {
        RTCAVFoundationVideoSource *videosource = [_peerConnectionFactory avFoundationVideoSourceWithConstraints:[self videoConstraints]];
        
        NSLog(@"WebRTCClient::initLocalMedia::addVideoTrack");
        _localVideoTrack = [_peerConnectionFactory videoTrackWithSource:videosource trackId:@"Video"];
        [_localMediaStream addVideoTrack:_localVideoTrack];
        
        _localPeer.localStream = _localMediaStream;
        [_localPeer.localStream.videoTracks[0] addRenderer:_localPeer.view];
        
        if ([_delegate respondsToSelector:@selector(client:didReceiveLocalVideo:)]) {
            [_delegate client:self didReceiveLocalVideo:_localPeer];
        }
    }
}

- (void)removeLocalMedia {
    NSLog(@"WebRTCClient::clearLocalMedia");
    if (self.localMediaStream) {
        [_localVideoTrack removeRenderer:_localPeer.view];
        [_delegate client:self didRemoveLocalVideo:_localPeer];
        
        _localVideoTrack = nil;
        _localAudioTrack = nil;
        _localMediaStream = nil;
    }
}

- (void)publish {
    NSLog(@"WebRTCClient::publish");
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    _localPeer.peerConnection = [_peerConnectionFactory
                                 peerConnectionWithConfiguration:config
                                 constraints:[self connectionConstraints] delegate:_localPeer];
    [_localPeer.peerConnection addStream:_localMediaStream];
    
    [_localPeer.peerConnection offerForConstraints:[self offerConstraints]
                                 completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error!= nil) {
            NSLog(@"offerForConstraints error %@", error);
            return;
        }
        
        [_localPeer.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            if (error != nil){
                NSLog(@"setLocalDescription error %@", [error localizedDescription]);
                return;
            }
            
            NSDictionary* message = @{
                                      @"direction":@"publish",
                                      @"command":@"sendOffer",
                                      @"streamInfo":@{
                                              @"applicationName":_applicationName,
                                              @"streamName":_streamName,
                                              @"sessionId":@"[empty]"
                                              },
                                      @"sdp":@{
                                              @"type":@"offer",
                                              @"sdp":sdp.sdp,
                                              },
                                      @"userData":@{
                                              @"param1":@"value1"
                                              },
                                      };
            
            [_webRtcSignal sendMessage:message];
        }];
    }];
}

- (void)setRemoteSdpLocalPeer:(NSString *)remoteSDP iceCandidates:(NSArray *)iceCandidates {
    NSLog(@"WebRTCClient::setRemoteSdpLocalPeer");
    RTCSessionDescription *_sdp = [[RTCSessionDescription alloc]
                                   initWithType:RTCSdpTypeAnswer sdp:remoteSDP];
    
     [_localPeer.peerConnection setRemoteDescription:_sdp completionHandler:^(NSError * _Nullable error) {
         if (error != nil) {
             NSLog(@"setRemoteDescription answer error %@", error);
             return;
         }
         
         for(NSDictionary *dict in iceCandidates) {
             NSString *mid = [dict objectForKey:@"sdpMid"];
             int sdpLineIndex = [[dict objectForKey:@"sdpMLineIndex"] intValue];
             NSString *sdp = [dict objectForKey:@"candidate"];
             
             RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:sdpLineIndex sdpMid:mid];
             
             [_localPeer.peerConnection addIceCandidate:candidate];
             NSLog(@"====>iceCandidates candidate : %@", [dict valueForKey:@"candidate"]);
             NSLog(@"====>iceCandidates sdpMLineIndex : %@", [dict valueForKey:@"sdpMLineIndex"]);
             NSLog(@"====>iceCandidates sdpMid : %@", [dict valueForKey:@"sdpMid"]);
         }
     }];
    
}

- (void)addRemotePeers:(NSString *)streamName {
    NSLog(@"WebRTCClient::addRemotePeers %@", streamName);
    WebRTCPeer *remotePeer = [[WebRTCPeer alloc] initWithDelegate:self];
    
    [_remotePeers setObject:remotePeer forKey:streamName];
    
    remotePeer.streamName = streamName;
    remotePeer.applicationName = _applicationName;
    remotePeer.peerConnection = [_peerConnectionFactory
                                 peerConnectionWithConfiguration:[self rtcConfiguration]
                                 constraints:[self connectionConstraints] delegate:remotePeer];
    NSDictionary* message = @{
                              @"direction":@"play",
                              @"command":@"getOffer",
                              @"streamInfo":@{
                                      @"applicationName":_applicationName,
                                      @"streamName":streamName,
                                      @"sessionId":@"[empty]"
                                      },
                              @"userData":@{
                                      @"param1":@"value1"
                                      },
                              };
    [_webRtcSignal sendMessage:message];
}

- (void)removeRemotePeers:(NSString *)streamName {
    NSLog(@"WebRTCClient::removeRemotePeers %@", streamName);
    WebRTCPeer *peer = [_remotePeers objectForKey:streamName];
    
    if(!peer) {
        return;
    }
    
    [_remotePeers removeObjectForKey:streamName];
    [self.delegate client:self didRemoveRemoteVideo:peer];
    [peer leave];
}

- (void)updateRunningStreams:(NSArray *)availableStreams {
    NSLog(@"WebRTCClient::updateRunningStreams %@", availableStreams);
    NSMutableDictionary *runningRemotePeers = [[NSMutableDictionary alloc] init];
    for (NSString *streamName in _remotePeers) {
        NSLog(@"WebRTCClient::updateRunningStreams runningPeer [%@]", streamName);
        [runningRemotePeers setObject:@1 forKey:streamName];
    }
    
    for (NSDictionary *dict in availableStreams) {
        NSString *streamName = [dict objectForKey:@"streamName"];
        
        [runningRemotePeers removeObjectForKey:streamName];
        if(![streamName isEqualToString:_streamName]) {
            
            [runningRemotePeers objectForKey:streamName];
            if(![_remotePeers objectForKey:streamName]) {
                // add remotePeer.....
                [self addRemotePeers:streamName];
                NSLog(@"Start ....... [%@]", streamName);
            }
        }
    }
    
    for (NSString *streamName in runningRemotePeers) {
        // Stop remotePeer..
        NSLog(@"Stop ....... [%@]", streamName);
        [self removeRemotePeers:streamName];
    }
}

- (void)subscribe:(NSDictionary *)streamInfo streamName:(NSString *)streamName remoteSDP:(NSDictionary *)remoteSDP {
    NSLog(@"WebRTCClient::subscribe %@", streamName);
//    if (remoteSDP && streamInfo && [_remotePeers objectForKey:streamName])
    {
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:[remoteSDP objectForKey:@"sdp"]];

        WebRTCPeer *remotePeer = [_remotePeers objectForKey:streamName];
        NSString *sessionID = [streamInfo valueForKey:@"sessionId"];
        remotePeer.sessionID = sessionID;
        
        NSLog(@"WebRTCClient::subscriberemotePeer.applicationName  %@", remotePeer.applicationName);
        NSLog(@"WebRTCClient::subscriberemotePeer.streamName  %@", remotePeer.streamName);
        
        __weak WebRTCClient *weakSelf = self;
        [remotePeer setRemoteSDP:sdp block:^(NSError *error) {
            NSLog(@"WebRTCClient::subscribe::setRemoteDescription");
            
            if (error != nil) {
                NSLog(@"Oooooops error  can not set remote offer sdp %@", error);
                return;
            }
            
            [remotePeer answerWithConstraints:[weakSelf answerConstraints] Block:^(RTCSessionDescription *sdp, NSError *error) {
                NSLog(@"WebRTCClient::subscribe::setRemoteDescription::answerWithConstraints");
                if(error!= nil){
                    NSLog(@"can not generate answer sdp %@", error);
                    return;
                }

                [remotePeer.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                    NSLog(@"WebRTCClient::subscribe::setRemoteDescription::setLocalDescription");
                    NSDictionary* message = @{
                        @"direction":@"play",
                        @"command":@"sendResponse",
                        @"streamInfo":@{
                            @"applicationName":_applicationName,
                            @"streamName":streamName,
                            @"sessionId":sessionID
                            },
                        @"sdp":@{
                            @"type":@"offer",
                            @"sdp":sdp.sdp,
                        },
                        @"userData":@{
                            @"param1":@"value1"
                        },
                    };

                    [_webRtcSignal sendMessage:message];
                }];
            }];
        }];
    }
}

- (void)setRemoteCandidates:(NSDictionary *)streamInfo iceCandidates:(NSArray *)iceCandidates {
    NSLog(@"WebRTCClient::setRemoteCandidates [%@], [%@]", streamInfo, iceCandidates);
    WebRTCPeer *remotePeer = [_remotePeers objectForKey:[streamInfo valueForKey:@"streamName"]];
    
    for(NSDictionary *dict in iceCandidates) {
        NSString *mid = [dict objectForKey:@"sdpMid"];
        int sdpLineIndex = [[dict objectForKey:@"sdpMLineIndex"] intValue];
        NSString *sdp = [dict objectForKey:@"candidate"];
        
        RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:sdpLineIndex sdpMid:mid];
        [remotePeer addCandidate:candidate];
    }
}


#pragma mark - wowzaProtocol
- (void)procAvailableStreams {
    NSDictionary* message = @{@"direction":@"play",
                              @"command":@"getAvailableStreams",
                              @"streamInfo":@{
                                      @"applicationName":_applicationName,
                                      @"streamName":@"",
                                      @"sessionId":@"[empty]"
                                      },
                              @"userData":@{
                                      @"param1":@"value1"
                                      },
                              };
    
    [_webRtcSignal sendMessage:message];
}

#pragma mark - WebRTCConfiguration
-(RTCConfiguration *) rtcConfiguration {
    RTCConfiguration* config = [[RTCConfiguration alloc] init];
    
    return config;
}

- (RTCMediaConstraints *)offerConstraints {
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio":@"false",
                                           @"OfferToReceiveVideo":@"false"
                                           };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:mandatoryConstraints
                                        optionalConstraints:nil];
    
    return constraints;
}

-(RTCMediaConstraints *)answerConstraints {
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio":@"true",
                                           @"OfferToReceiveVideo":@"true"
                                           };
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:mandatoryConstraints
                                        optionalConstraints:nil];
    return constraints;
}


-(RTCMediaConstraints *)videoConstraints
{
    NSDictionary *videoConstraints = @{
                                       @"maxWidth":[NSString stringWithFormat:@"%d", 1280],
                                       @"maxHeight":[NSString stringWithFormat:@"%d", 1280],
                                       @"minWidth":[NSString stringWithFormat:@"%d", 120],
                                       @"minHeight":[NSString stringWithFormat:@"%d", 120],
                                       @"minFrameRate":[NSString stringWithFormat:@"%d", 15],
                                       @"maxFrameRate":[NSString stringWithFormat:@"%d", 15]
                                       };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:videoConstraints
                                        optionalConstraints:nil];
    return constraints;
}


- (RTCMediaConstraints *)connectionConstraints
{
    NSDictionary *optionalConstraints = @{
                                          @"DtlsSrtpKeyAgreement":@"true",
                                          @"googSuspendBelowMinBitrate":@"false",
                                          @"googCombinedAudioVideoBwe":@"true"
                                          };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:nil
                                        optionalConstraints:optionalConstraints];
    
    return constraints;
}

#pragma mark - WebRTCSignalingDelegate

- (void)socketChannel:(WebRTCSignaling *)socketChannel webSocketDidOpen:(NSString *)message {
    NSLog(@"WebRTCClient::socketChannel::webSocketDidOpen");
    [self publish];
}

- (void)socketChannel:(WebRTCSignaling *)socketChannel didReceiveMessage:(NSDictionary *)data {
    NSLog(@"WebRTCClient::socketChannel::didReceiveMessage");
    NSString* command = [data objectForKey:@"command"];
    int status = [[data objectForKey:@"status"] intValue];
    
    if(status == 200) {
        if([command isEqualToString:@"getAvailableStreams"]) {
            
            NSLog(@"availableStreams");
            NSArray *availableStreams = [data valueForKeyPath:@"availableStreams"];
            [self updateRunningStreams:availableStreams];
            
        } else if([command isEqualToString:@"sendOffer"]) {
            NSLog(@"sendOffer");
            NSDictionary *sdp = [data valueForKeyPath:@"sdp"];
            if (sdp == nil) {
                NSLog(@"event published can not find sdp");
                return;
            }
            NSArray *iceCandidates = [data valueForKeyPath:@"iceCandidates"];
            
            NSString *sdpStr = [sdp objectForKey:@"sdp"];
            [self setRemoteSdpLocalPeer:sdpStr iceCandidates:iceCandidates];
            
        } else if([command isEqualToString:@"sendResponse"]) {
            
            NSLog(@"===========>>>>>>>>>sendResponse");
            NSDictionary *streamInfo = [data valueForKeyPath:@"streamInfo"];
            NSArray *iceCandidates = [data valueForKeyPath:@"iceCandidates"];
            [self setRemoteCandidates:streamInfo iceCandidates:iceCandidates];
            
        } else if([command isEqualToString:@"getOffer"]) {
            
            NSLog(@"getOffer");
            NSDictionary *streamInfo = [data valueForKeyPath:@"streamInfo"];
            NSString *streamName = [streamInfo valueForKey:@"streamName"];
            NSDictionary *sdp = [data valueForKeyPath:@"sdp"];
            
            NSLog(@"getOffer streamInfo [%@]", streamInfo);
            NSLog(@"getOffer streamName [%@]", streamName);
            NSLog(@"getOffer sdp [%@]", sdp);
            
//            if(streamInfo && streamName && sdp) {
                [self subscribe:streamInfo streamName:streamName remoteSDP:sdp];
//            }
        }
    }
    
}

- (void)socketChannel:(WebRTCSignaling *)socketChannel didChangeState:(WebRTCSignalingState)state {
    NSLog(@"WebRTCClient::socketChannel::didChangeState");
    
}

- (void)socketChannel:(WebRTCSignaling *)socketChannel sendEventMessage:(NSString *)message {
    NSLog(@"WebRTCClient::socketChannel::sendEventMessage");
    
    if ([message isEqualToString:@"getAvailableStreams"]) {
        [self procAvailableStreams];
    }
}

#pragma mark - WebRTCPeerDelegate

- (void)peer:(WebRTCPeer *)peer didGotCandidate:(RTCIceCandidate *)candidate {
    NSLog(@"WebRTCClient::peer::didGotCandidate [%@]", candidate);
    
}

- (void)peer:(WebRTCPeer *)peer didOccurError:(NSInteger *)errorCode {
    NSLog(@"WebRTCClient::peer::didOccurError [%zd]", errorCode);
}

- (void)peer:(WebRTCPeer *)peer didReceiveRemoteVideo:(RTCVideoTrack *)track {
    NSLog(@"WebRTCClient::peer::didReceiveRemoteVideo [%@]", peer.streamName);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [track addRenderer:peer.view];
        [self.delegate client:self didReceiveRemoteVideo:peer];
    });
}

- (void)peer:(WebRTCPeer *)peer didRemoveRemoteVideo:(RTCVideoTrack *)track {
    NSLog(@"WebRTCClient::peer::didRemoveRemoteVideo streamName [%@]", peer.streamName);
    dispatch_async(dispatch_get_main_queue(), ^{
        [track removeRenderer:peer.view];
        [self.delegate client:self didRemoveRemoteVideo:peer];
    });
}

- (void)sendMessage:(NSDictionary *)message {
    NSLog(@"WebRTCClient::peer::sendMessage [%@]", message);
}

@end



//
//  ViewController.m
//  wowza-webrtc-ios
//
//  Created by 안영환 on 2018. 1. 31..
//

#import "ViewController.h"
#import "WebRTCClient.h"

@interface ViewController () <WebRTCClientDelegate> {
    WebRTCClient *_webrtcClient;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self requestAudioAcess:^(BOOL granted) {
        BOOL audioGranted = granted;
        [self requestVideoAcess:^(BOOL granted) {
            BOOL videoGranted = granted;
            if (audioGranted && videoGranted) {
                _webrtcClient = [[WebRTCClient alloc] initWithDelegate:self];
                [_webrtcClient initLocalMedia];
            }
        }];
    }];
    
//    _webrtcClient = [[WebRTCClient alloc] initWithDelegate:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)requestAudioAcess:(void (^)(BOOL granted))block {
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    
    if (permissionStatus == AVAudioSessionRecordPermissionUndetermined) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL grante) {
            // CALL YOUR METHOD HERE - as this assumes being called only once from user interacting with permission alert!
            if (grante) {
                block(TRUE);
                // Microphone enabled code
            }
            else {
                block(FALSE);
                // Microphone disabled code
            }
        }];
    } else if(permissionStatus == AVAudioSessionRecordPermissionDenied) {
        block(FALSE);
    } else if(permissionStatus == AVAudioSessionRecordPermissionGranted) {
        block(TRUE);
        
    } else {
        block(FALSE);
    }
}


- (void)requestVideoAcess:(void (^)(BOOL granted))block {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        
        block(TRUE);
        
    } else if(authStatus == AVAuthorizationStatusDenied){
        // denied
        block(FALSE);
    } else if(authStatus == AVAuthorizationStatusRestricted){
        // restricted, normally won't happen
        block(FALSE);
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL grante) {
            if(grante){
                block(TRUE);
            } else {
                block(FALSE);
            }
        }];
    } else {
        // impossible, unknown authorization status
    }
}

- (CGRect)videoViewFrame:(int)index {
    float width = self.view.frame.size.width/2;
    float height = width;
    float x = (index%2) * width;
    float y = (index/2) * width;
    
    return CGRectMake(x, y, width, height);
}

#pragma mark - WebRTCClientDelegate

- (void)client:(WebRTCClient *)client didReceiveRemoteVideo:(WebRTCPeer *)peer {
    NSLog(@"didReceiveRemoteVideo");
    NSMutableArray *remotePeers  = [NSMutableArray arrayWithArray:[client.remotePeers.allValues copy]];
    [remotePeers insertObject:client.localPeer atIndex:0];
    
    CGRect frame = [self videoViewFrame:0];
    [peer.view  setSize:frame.size];
    peer.view.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:peer.view];
    peer.view.backgroundColor = [UIColor blackColor];
    
    int i = 0;
    for (WebRTCPeer *peer in remotePeers) {
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
}

- (void)client:(WebRTCClient *)client didReceiveLocalVideo:(WebRTCPeer *)peer {
    NSLog(@"didReceiveLocalVideo");
    NSMutableArray *remotePeers  = [NSMutableArray arrayWithArray:[client.remotePeers.allValues copy]];
    [remotePeers insertObject:client.localPeer atIndex:0];
    
    CGRect frame = [self videoViewFrame:0];
    [peer.view  setSize:frame.size];
    peer.view.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:peer.view];
    peer.view.backgroundColor = [UIColor blackColor];
    
    int i = 0;
    for (WebRTCPeer *peer in remotePeers) {
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
}

- (void)client:(WebRTCClient *)client didRemoveRemoteVideo:(WebRTCPeer *)peer {
    NSLog(@"didRemoveRemoteVideo");
    [peer.view removeFromSuperview];
    
    NSMutableArray *remotePeers = [NSMutableArray arrayWithArray:[client.remotePeers.allValues copy]];
    [remotePeers insertObject:client.localPeer atIndex:0];
    
    int i = 0;
    for(WebRTCPeer* peer in remotePeers) {
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
}

- (void)client:(WebRTCClient *)client didRemoveLocalVideo:(WebRTCPeer *)peer {
    NSLog(@"didRemoveLocalVideo ");
    [peer.view removeFromSuperview];
    NSMutableArray *remotePeers = [NSMutableArray arrayWithArray:[client.remotePeers.allValues copy]];
//    [remotePeers insertObject:client.localPeer atIndex:0];
    
    int i = 0;
    for(WebRTCPeer *peer in remotePeers){
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
}

@end

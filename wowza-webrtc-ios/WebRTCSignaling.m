//
//  WebRTCSignaling.m
//  wowza-webrtc-ios
//
//

#import "WebRTCSignaling.h"

static NSTimeInterval kWebsocketKeepAliveInterval = 3.0;

@interface WebRTCSignaling () <SRWebSocketDelegate>

@property (nonatomic, strong) NSTimer *websocketKeepAliveTimer;

//- (void)connect;
//- (void)disconnect;

@end

@implementation WebRTCSignaling {
    NSString *_url;
    SRWebSocket *_socket;
}

- (instancetype)initWithURL:(NSString *)url delegate:(id<WebRTCSignalingDelegate>)delegate {
    NSLog(@"WebRTCSignaling::initWithURL");
    self = [super init];
    _delegate = delegate;
    _url = url;
    
    _socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:_url]];
    _socket.delegate = self;
    [_socket open];

    return self;
}

//- (void)connect {
//    NSLog(@"WebRTCSignaling::connect");
//    [_socket open];
//}

//- (void)disconnect {
//    NSLog(@"WebRTCSignaling::disconnect");
//    [_socket close];
//}

- (void)sendMessage:(NSDictionary *)message {
    NSLog(@"WebRTCSignaling::sendMessage [%@]", message);
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [_socket send:jsonString];
    }
    
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"WebRTCSignaling::webSocketDidOpen");
    [self.delegate socketChannel:self webSocketDidOpen:@"OK"];
    
    [self scheduleTimer];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"WebRTCSignaling::didReceiveMessage ==== onMessage ");
    NSString *messageString = message;
    NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:messageData
                                                    options:0
                                                      error:nil];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary *wssMessage = jsonObject;
    [self.delegate socketChannel:self didReceiveMessage:wssMessage];
}

-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
//    self.state = kSignalingStateError;
    NSLog(@"didFailWithError %@", error);
    [self invalidateTimer];
    
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
//    self.state = kSignalingStateClosed;
    NSLog(@"didCloseWithCode %@", reason);
    [self invalidateTimer];
}


#pragma mark - Timer
- (void)scheduleTimer {
    [self invalidateTimer];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:kWebsocketKeepAliveInterval target:self selector:@selector(handleTimer:) userInfo:nil repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.websocketKeepAliveTimer = timer;
}

- (void)invalidateTimer {
    [self.websocketKeepAliveTimer invalidate];
    self.websocketKeepAliveTimer = nil;
}

- (void)handleTimer:(NSTimer *)timer {
    [self sendPing];
    [self scheduleTimer];
}

- (void)sendPing {
    NSLog(@"WebRTCSingaling::sendPing");
//    [_socket sendPing:nil];
    [self.delegate socketChannel:self sendEventMessage:@"getAvailableStreams"];
}

@end

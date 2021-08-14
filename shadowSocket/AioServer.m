//
//  ViewController.m
//  shadowSocket
//
//  Created by 张林 on 2021/3/28.
//

#import "AioServer.h"
#import "GCDAsyncSocket.h" // for TCP
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
AioServer *aioServer;
/*---------------------------参数定义-------------------*/
int localPort = 18080;
NSString *username=@"zhanglin";
NSString *serverIp=@"185.23.200.146:28083";
NSString*host=@"aws,github,docker,youtu,coursera,medium,poems,twimg,twitter,wikipedia,google,facebook,fbcdn,dispatch,youtube,gstatic,doubleclick,ytimg,ggpht,voachinese";

/*-------------------------对象定义-----------------------------*/
@implementation AIOContext
@end

@implementation AioServer
//--------------------------dictAIOContext同步操作--------------------------
-(void) put:(GCDAsyncSocket *)key value:(AIOContext*) context{
    @synchronized (self) {
        NSString *keyStr = [[NSNumber numberWithLong:(long)key] stringValue];
        [self.dictAIOContext setValue:context forKey:keyStr];
    }
}
-(void) remove:(GCDAsyncSocket *)key{
    @synchronized (self) {
        NSString *keyStr = [[NSNumber numberWithLong:(long)key] stringValue];
        [self.dictAIOContext removeObjectForKey:keyStr];
    }
}
-(AIOContext*) get:(GCDAsyncSocket *)key{
    @synchronized (self) {
        NSString *keyStr = [[NSNumber numberWithLong:(long)key] stringValue];
        return [self.dictAIOContext valueForKey:keyStr];
    }
}
-(NSArray*) getAllValues{
    @synchronized (self) {
        return [self.dictAIOContext allValues];
    }
}
-(void) removeAll{
    @synchronized (self) {
        return [self.dictAIOContext removeAllObjects];
    }
}


//----------界面初始化---------------------------------------------------------
- (AioServer *)init:(UITextView *) textview{
    self = [super init];
    // Do any additional setup after loading the view.
    self.textview = textview;
    // 异步io初始化
    self.serverSocket=[[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    [self.serverSocket performBlock:^{
        [self.serverSocket enableBackgroundingOnSocket];
    }];
    self.dictAIOContext = [[NSMutableDictionary alloc] init];
    self.configHost = [host componentsSeparatedByString:@","];
    // 心跳定时器
    self.heart = [NSTimer timerWithTimeInterval:19 target:self selector:@selector(sendHeart) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.heart forMode:NSRunLoopCommonModes];
    [self appendText:serverIp];
    return self;
}

-(void)appendText: (NSString *) str{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textview.text =  [self.textview.text stringByAppendingFormat:@"%@\n", str];
        [self.textview scrollRangeToVisible:NSMakeRange(self.textview.text.length, 1)];
    });
}

-(void)start{
    NSError *error=nil;
    if([self.serverSocket acceptOnPort:localPort error:&error]){
        @try{
            NSRange range = [self.textview.text rangeOfString:@"\n"];
            serverIp = [self.textview.text substringToIndex:range.location];
            [self appendText:[@"" stringByAppendingFormat:@"server: %d, %@", localPort, serverIp]];
        }@catch(NSException *ex){}
    }else{
        [self appendText:[@"" stringByAppendingFormat:@"start failed: %@", error]];
    }
}

-(void)stop{
    [self appendText:@"already stop server"];
    [self.serverSocket disconnect];
    [self removeAll];
}

-(void)setAllAboard: (Boolean) allAoard{
    if(allAoard){
        self.configHost = [@"*" componentsSeparatedByString:@","];
        [self appendText:@"already start AllAboard"];
    }else{
        self.configHost = [host componentsSeparatedByString:@","];
        [self appendText:@"already stop AllAboard"];
    }
}

//--事件驱动select-nio: accept  read close----------------------------------
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    // 注册请求端连接上下文
    AIOContext *context = [AIOContext alloc];
    context.state = @"getHttpHead";
    context.inSocket = newSocket;
    [newSocket performBlock:^{
        [newSocket enableBackgroundingOnSocket];
    }];
    [self put:context.inSocket value:context];
    // 继续读取数据
    [newSocket readDataWithTimeout:-1 tag:0];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    // 获取sock对应的连接上下文
    AIOContext *context = [self get:sock];
    if(context==nil){
        [sock disconnect];
        return;
    }
    @try{
        [self aioHandle:context input:data];
    }@catch(NSException *ex){
        NSLog(@"didReadData: %@", ex);
    }
    
    // 继续读取数据
    if([context.state isEqualToString:@"recevieEncryption"]){
        [sock readDataWithTimeout:81 tag:0];
    }else if(![context.state isEqualToString:@"close"]){
        [sock readDataWithTimeout:-1 tag:0];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    // 获取sock对应的连接上下文
    AIOContext *context = [self get:sock];
    if(context==nil){
        return;
    }
    // 处理输入流data
    if(![context.state isEqualToString:@"close"]){
        context.state = @"close";
        [self aioHandle:context input:nil];
    }
}
//------------aioserver-----------------------------------------------------------
-(void) aioHandle:(AIOContext *)context input:(NSData *)data{
    /*----------------------读取请求头["@close"不可能抛异常]-----------------------*/
    if([context.state isEqual:@"getHttpHead"]){
        NSString *receive=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        // 检查http协议
        NSString *protocol = [self httpProtocol:receive configHost:self.configHost];
        if([protocol isEqualToString:@"UNSURPPORT"]){
            context.state=@"close";
            [self aioHandle:context input: nil];
            return;
        }
        // 检查ipport
        NSArray *ipport=[self ipPort:receive];
        if(ipport==nil){
            context.state=@"close";
            [self aioHandle:context input: nil];
            return;
        }
        if([protocol isEqualToString:@"HTTPS_ENCRYPTION"]){
            ipport = [serverIp componentsSeparatedByString:@":"];
        }
        // 检查连接远端
        context.outSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
        [context.outSocket performBlock:^{
            [context.outSocket enableBackgroundingOnSocket];
        }];
        if (![context.outSocket connectToHost:ipport[0] onPort:[ipport[1] intValue] error:nil]){
            NSLog(@"服务器连接失败---%@",nil);
            context.state=@"close";
            [self aioHandle:context input: nil];
            return;
        }
        // 注册接收端context
        AIOContext *newContext = [AIOContext alloc];
        newContext.inSocket = context.outSocket;
        newContext.outSocket = context.inSocket;
        [self put:newContext.inSocket value:newContext];
        // 转发输出请求
        if([protocol isEqualToString:@"HTTP"]){
            context.state = @"sendDirect";
            newContext.state = @"sendDirect";
            [context.outSocket readDataWithTimeout:-1 tag:0];
            [self aioHandle:context input:data];
        }
        if([protocol isEqualToString:@"HTTPS_DIRECT"]){
            context.state = @"sendDirect";
            newContext.state = @"sendDirect";
            data = [@"HTTP/1.1 200 Connection Established\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
            [context.outSocket readDataWithTimeout:-1 tag:0];
            [context.inSocket writeData:data withTimeout:-1 tag:0];
        }
        if([protocol isEqualToString:@"HTTPS_ENCRYPTION"]){
            context.state = @"sendEncryption";
            newContext.state = @"recevieEncryption";
            context.data = [[NSData alloc]init];
            newContext.data = [[NSData alloc]init];
            // 添加用户认证
            [context.outSocket readDataWithTimeout:-1 tag:0];
            
            receive = [self addAuthSession:receive session:@"simple"];
            [self aioHandle:context input:[receive dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    /*----------------------发送明文-----------------------*/
    else if([context.state isEqual:@"sendDirect"]){
        [context.outSocket writeData:data withTimeout:-1 tag:0];
    }
    /*----------------------发送密文: 分块发送8192-----------------------*/
    else if ([context.state isEqual:@"sendEncryption"]){
        data = [self encoderAndPacakage:data];
        @synchronized (context){
            [context.outSocket writeData:data withTimeout:-1 tag:0];
        }
    }
    /*----------------------接受密文: 分块接受8192-----------------------*/
    else if ([context.state isEqual:@"recevieEncryption"]){
        // 接受缓冲区可能有残留字符
        NSMutableData *mutableData = [[NSMutableData alloc]initWithData:context.data];
        [mutableData appendData:data];
        // 解密并发送
        data = [self dePacakageAndDecoder:&mutableData];
        context.data = mutableData;
        [context.outSocket writeData:data withTimeout:-1 tag:0];
    }
    /*----------------------关闭请求-----------------------*/
    else if([context.state isEqual:@"close"]){
        @try{
            if(context.inSocket!=nil){
                [context.inSocket disconnect];
                [self remove:context.inSocket];
                [context.outSocket disconnect];
                [self remove:context.outSocket];
            }
        }@catch(NSException *exception){
            NSLog(@"closeException: %@", exception);
        }
    }
}
// 定时器
-(void) sendHeart{
    NSArray *contexts = [self getAllValues];
    Byte HeartBearting[1] = {255};
    for(int i=0; i<contexts.count; i++){
        @try{
            if(contexts[i]==nil){
                continue;
            }
            AIOContext* tmp = (AIOContext*)contexts[i];
            if([tmp.state isEqualToString:@"sendEncryption"]&&[tmp.data length]==0){
                @synchronized (tmp) {
                    [tmp.outSocket writeData:[[NSData alloc]initWithBytes:HeartBearting length:1] withTimeout:-1 tag:0];
                    NSLog(@"send heart");
                }
            }
        }@catch(NSException *e){
            NSLog(@"%@", e);
        }@catch(NSError *er){
            NSLog(@"NSError: %@", er);
        }
    }
}
//---------------------加解密：----------------------------------------------------------
#define N 16
#define PLAINT_MAX 8192
#define ENCRPTION_MAX (PLAINT_MAX+N)
-(NSData*) encoderAndPacakage:(NSData *) content{
    NSMutableData *data = [[NSMutableData alloc]init];
    
    for(long p=0, len = [content length];p<len;p+=PLAINT_MAX){
        NSData *tmp=[content subdataWithRange:NSMakeRange(p,MIN(len-p, PLAINT_MAX))];
        
        tmp = [self encoder:tmp];
        Byte packageLen[2] = { ([tmp length]>>8)&255, [tmp length] & 255};
        [data appendBytes:packageLen length:2];
        [data appendData:tmp];
    }
    return data;
}
-(NSData*) dePacakageAndDecoder:(NSData **) content{
    Byte *tmp = (Byte *)[*content bytes];
    NSMutableData *data = [[NSMutableData alloc]init];
    long p=0,len = [*content length];
    while(p+2<=len ){
        // 读到-1心跳字节
        if(tmp[p]==255){
            p++;
            continue;
        }
        // 读取长度
        long cnt = ((tmp[p]&255)<<8)+(tmp[p+1]&255);
        if(p+2+cnt>len){
            break;
        }
        // 解密
        NSData *encryption=[*content subdataWithRange:NSMakeRange(p+2, cnt)];
        [data appendData:[self decoder:encryption]];
        p = p+2+cnt;
    }
    *content = [*content subdataWithRange:NSMakeRange(p, len-p)];
    return data;
}
-(NSData*) encoder:(NSData *) content{
    // 将content加密: 16字节密钥+最多8192字节密文
    Byte bytes[ENCRPTION_MAX];
    // 16字节随机密钥
    for(int i=0; i<N; i++){
        bytes[i] =  arc4random();
    }
    // 加密明文
    Byte *src = (Byte*)[content bytes];
    for(int i=0,j=0; i<[content length]; i++,j++){
        bytes[N+i] = bytes[j==N?0:j] + src[i];
    }
    
    return [[NSData alloc] initWithBytes:bytes length:[content length]+N];
}
-(NSData*) decoder:(NSData *) content{
    // 将content解密，16字节密钥+最多8192字节密文
    Byte *src = (Byte*)[content bytes];
    long len = [content length];
    // 解密密文
    Byte bytes[PLAINT_MAX];
    for(int i=0,j=0; i<len-N; i++,j++){
        bytes[i] = src[N+i] - src[j==N?0:j];
    }
    return [[NSData alloc] initWithBytes:bytes length:len-N];
}
//--------------------------HTTP协议----------------------------------------------------------
-(NSArray*)ipPort:(NSString*)head{
    if(head==nil){
        return nil;
    }
    // hostname的头
    NSRange idx = [head rangeOfString:@"Host: "];
    if((int)idx.location==-1){
        idx = [head rangeOfString:@"host: "];
        if((int)idx.location==-1){
            return nil;
        }
    }
    NSString *host = [head substringFromIndex:idx.location+idx.length];
    // hostname的尾
    idx = [host rangeOfString:@"\r\n"];
    if((int)idx.location!=-1){
        host = [host substringToIndex:idx.location];
    }
    // hostname带端口
    idx = [host rangeOfString:@":"];
    NSString *ip,*port;
    if((int)idx.location!=-1){
        ip = [host substringToIndex:idx.location];
        port = [host substringFromIndex:idx.location+idx.length];
        return [NSArray arrayWithObjects:ip,port,nil];
    }
    // hostname不带端口
    ip = host;
    port = @"80";
    if([head hasPrefix:@"CONNECT"]){
        port = @"443";
    }
    idx = [head rangeOfString:[ip stringByAppendingString:@":"]];
    if((int)idx.location!=-1){
        long p = idx.location + idx.length;
        long q = p;
        while([head characterAtIndex:p]>='0'&&[head characterAtIndex:p]<='9'){
            p++;
        }
        NSRange   range =  NSMakeRange(q, p-q);
        port = [head substringWithRange:range];
    }
    
    return [NSArray arrayWithObjects:ip,port,nil];
}

-(NSString *) httpProtocol:(NSString*) head configHost: (NSArray *)configHost{
    if([head hasPrefix:@"CONNECT"]){
        if([@"*" isEqualToString:configHost[0]]){
            return @"HTTPS_ENCRYPTION";
        }
        for(int i=0; i<configHost.count; i++){
            if([head containsString:configHost[i]]){
                return @"HTTPS_ENCRYPTION";
            }
        }
        return @"HTTPS_DIRECT";
    }
    if([head hasPrefix:@"GET"]||[head hasPrefix:@"Get"]||[head hasPrefix:@"get"]){
        return @"HTTP";
    }
    if([head hasPrefix:@"POST"]||[head hasPrefix:@"Post"]||[head hasPrefix:@"post"]){
        return @"HTTP";
    }
    if([head hasPrefix:@"HEAD"]||[head hasPrefix:@"Head"]||[head hasPrefix:@"head"]){
        return @"HTTP";
    }
    if([head hasPrefix:@"PUT"]||[head hasPrefix:@"Put"]||[head hasPrefix:@"put"]){
        return @"HTTP";
    }
    if([head hasPrefix:@"DELETE"]||[head hasPrefix:@"Delete"]||[head hasPrefix:@"delete"]){
        return @"HTTP";
    }
    return @"UNSURPPORT";
}

-(NSString *) addAuthSession:(NSString*) head session:(NSString*)data{
    head = [head substringToIndex:[head length]-2];
    return [head stringByAppendingFormat:@"username: %@:%@\r\n\r\n", username,data];
}

@end

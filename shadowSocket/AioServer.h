#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h" // for TCP
@interface AioServer: NSObject <GCDAsyncSocketDelegate>
// 主界面按钮
   @property UITextView *textview;
   @property NSArray *configHost;
// 异步io
   @property(strong) GCDAsyncSocket *serverSocket;
   @property NSMutableDictionary *dictAIOContext;
   @property NSTimer *heart;

    -(AioServer *) init:(UITextView *) textview;
    -(void) start;
    -(void) stop;
    -(void) setAllAboard: (Boolean) allAoard;
    -(void) sendHeart;
@end

@interface AIOContext : NSObject
    @property NSString *state;           //当前状态
    @property NSData *data;              //缓存数据
    @property GCDAsyncSocket *inSocket;  //输入端
    @property GCDAsyncSocket *outSocket; //输出端
    @property NSString *rsaPubKey;       //rsa公钥
    @property NSString *aesKey;          //aes密钥
@end





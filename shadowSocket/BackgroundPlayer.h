#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/*
————————————————
版权声明：本文为CSDN博主「Wain丶」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq_38520096/article/details/102626210
*/

@interface BackgroundPlayer : NSObject <AVAudioPlayerDelegate>{
    AVAudioPlayer* _player;
}
- (BackgroundPlayer*) init;
- (void)startPlayer;

- (void)stopPlayer;
@end

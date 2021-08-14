#import "BackgroundPlayer.h"

/*
————————————————
版权声明：本文为CSDN博主「Wain丶」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq_38520096/article/details/102626210
*/

@implementation BackgroundPlayer

- (BackgroundPlayer *)init
{
    if (!_player) {
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"WhiteNoice" withExtension:@"mp3"];
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        audioPlayer.numberOfLoops = NSUIntegerMax;
        
        _player = audioPlayer;
        [_player setVolume:1.0];
    }
    return self;
}

- (void) startPlayer{
    [_player stop];
    [_player prepareToPlay];
    [_player play];
}

- (void)stopPlayer
{
    if (_player) {
        [_player stop];
        _player = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:NO error:nil];
        NSLog(@"stop in play background success");
    }
}

@end

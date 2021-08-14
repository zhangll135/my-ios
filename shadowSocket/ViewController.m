//
//  ViewController.m
//  shadowSocket
//
//  Created by 张林 on 2021/3/28.
//

#import "ViewController.h"
#import "AioServer.h" // for TCP

@interface ViewController ()
@end

@implementation ViewController

// 主界面按钮
UIButton * button;
UIButton * allAboard;
UITextView *textview;
extern AioServer* aioServer;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame=CGRectMake(40, 40, 240, 30);
    button.backgroundColor=[UIColor redColor];
    [button setTitle:@"启动客户端" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    allAboard = [UIButton buttonWithType:UIButtonTypeSystem];
    allAboard.frame=CGRectMake(40, 100, 240, 30);
    allAboard.backgroundColor=[UIColor redColor];
    [allAboard setTitle:@"启动AllAboard" forState:UIControlStateNormal];
    [allAboard addTarget:self action:@selector(allAboard) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:allAboard];

    textview = [[UITextView alloc] initWithFrame:CGRectMake(10, 140, 400, 400)];
    textview.text = @"";//设置显示的文本内容
    textview.layoutManager.allowsNonContiguousLayout= NO;
    [textview setFont:[UIFont systemFontOfSize:18]];
    [self.view addSubview:textview];
    
    aioServer = [[AioServer alloc]init:textview];
    [self start];
}

-(void)start{
    if([button.titleLabel.text isEqualToString:@"启动客户端" ]){
        [button setTitle:@"停止客户端" forState:UIControlStateNormal];
        [aioServer start];
    }else{
        [button setTitle:@"启动客户端" forState:UIControlStateNormal];
        [aioServer stop];
    }
}

-(void)allAboard{
    if([allAboard.titleLabel.text isEqualToString:@"启动AllAboard" ]){
        [allAboard setTitle:@"停止AllAboard" forState:UIControlStateNormal];
        [aioServer setAllAboard:true];
    }else{
        [allAboard setTitle:@"启动AllAboard" forState:UIControlStateNormal];
        [aioServer setAllAboard:false];
    }
}
@end

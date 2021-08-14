//
//  AppDelegate.h
//  shadowSocket
//
//  Created by 张林 on 2021/3/28.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;
//  后台运行，支持13以下兼容
@property (nonatomic, strong) UIWindow *window;


- (void)saveContext;


@end


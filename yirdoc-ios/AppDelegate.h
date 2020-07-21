//
//  AppDelegate.h
//  yirdoc-ios
//
//  Created by 高存彬 on 2020/4/8.
//  Copyright © 2020 yirdoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define kINNotificationIdentifier @"IN"
#define kOUTNotificationIdentifier @"OUT"
#define kSTOPNotificationIdentifier @"STOP"

#define kCONNECTNotificationIdentifier @"CONNECT"
#define kDISCONNECTNotificationIdentifier @"DISCONNECT"

typedef struct DeviceStatus {
    int powerValue;
    int wuhuaRate;
    NSString * _Nonnull firmversion;
    NSString * _Nonnull serialnum;
    NSString * _Nonnull manufacturerName;
} DeviceStatus;

typedef enum inOutState{
    breathIn, breathOut, breathInStop, breathOutStop
}inOutState;

typedef struct GameState {
    inOutState state;
    NSTimeInterval breathIn_interval ;
    NSTimeInterval start_time;
    NSInteger round;
    NSTimeInterval totalTime;
    NSInteger currentScore;//当前关卡得分
} GameState;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow * _Nonnull window;
@property (strong, nonatomic) NSMutableDictionary * _Nonnull globalDic;
@property (nonatomic, assign) DeviceStatus * _Nonnull deviceStatus;
@property (nonatomic, strong) CBPeripheral * _Nonnull peripheral;
@property (nonatomic, assign) NSTimeInterval totalTimeInterval;
@property (nonatomic, assign) NSTimeInterval statTimeInterval;
@property (nonatomic, assign) NSTimeInterval endTimeInterval;

@property (nonatomic, assign) GameState * _Nonnull gameState;

-(void)startScan;
-(void)powerOff;
-(void)changeWuhuaRate:(uint8_t) val;
-(void)readWuhuaRate;
-(void)readcurrentPower;

@end


//
//  ViewController.m
//  yirdoc-ios
//
//  Created by 高存彬 on 2020/4/8.
//  Copyright © 2020 yirdoc. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *m_ble_status;
@property (weak, nonatomic) IBOutlet UILabel *m_firm_version;
@property (weak, nonatomic) IBOutlet UILabel *m_serial_num;
@property (weak, nonatomic) IBOutlet UILabel *m_power_percent;
@property (weak, nonatomic) IBOutlet UITextView *m_breath_opt_log;
@property (weak, nonatomic) IBOutlet UIButton *m_btn_high;
@property (weak, nonatomic) IBOutlet UIButton *m_btn_middle;
@property (weak, nonatomic) IBOutlet UIButton *m_btn_low;

@end

@implementation ViewController{
    NSArray *_btnArray;
    AppDelegate *_appDelegate;
    NSInteger wuhuaRate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    //////////////////NOTIFICATION/////////////
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(breathOutAction) name:kOUTNotificationIdentifier object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(breathStopAction) name:kSTOPNotificationIdentifier object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(breathInAction) name:kINNotificationIdentifier object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectUp) name:kCONNECTNotificationIdentifier object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectDown) name:kDISCONNECTNotificationIdentifier object:nil];
    
    // Do any additional setup after loading the view.
}

-(void)breathInAction{
    self->_m_breath_opt_log.text = [NSString stringWithFormat:@"%@, [Breath In]",self->_m_breath_opt_log.text];
}
-(void)breathStopAction{
    self->_m_breath_opt_log.text = [NSString stringWithFormat:@"%@, [Breath Stop]",self->_m_breath_opt_log.text];
}
-(void)breathOutAction{
    self->_m_breath_opt_log.text = [NSString stringWithFormat:@"%@, [Breath Out]",self->_m_breath_opt_log.text];
}
-(void)connectUp{
        
    self->_m_breath_opt_log.text = [NSString stringWithFormat:@"%@, [Connecting]",self->_m_breath_opt_log.text];
    _m_ble_status.text = @"Connecting";
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateBLEView];
    });
}
-(void)connectDown{
    self->_m_breath_opt_log.text = [NSString stringWithFormat:@"%@, [Disconnect]",self->_m_breath_opt_log.text];
    _m_ble_status.text = @"Disconnected";
}

- (IBAction)ActionScan:(id)sender {
    
    _m_ble_status.text = @"Scaning...";
    self->_m_breath_opt_log.text = @"[Scan]";
    [_appDelegate startScan];
}

-(void) updateBLEView{
    
    _m_ble_status.text = [NSString stringWithFormat:@"Connected[%@]",_appDelegate.deviceStatus->manufacturerName];
    self->_m_breath_opt_log.text = [NSString stringWithFormat:@"%@, [Connected]",self->_m_breath_opt_log.text];
        
    self->_m_power_percent.text = [NSString stringWithFormat:@"%d%%", _appDelegate.deviceStatus->powerValue];
    
    self->_m_firm_version.text = _appDelegate.deviceStatus->firmversion;
    
    self->_m_serial_num.text = _appDelegate.deviceStatus->serialnum;
    
    wuhuaRate = _appDelegate.deviceStatus->wuhuaRate;
    _m_btn_low.selected = false;
    _m_btn_middle.selected = false;
    _m_btn_high.selected = false;
    switch(wuhuaRate){
        case 0:
            _m_btn_low.selected = true;
            break;
        case 2:
            _m_btn_middle.selected = true;
            break;
        case 4:
            _m_btn_high.selected = true;
            break;
        default:
            break;
    }
}

- (IBAction)ActionPowerOff:(id)sender {
    
    [_appDelegate powerOff];
    
}
- (IBAction)ActionRateHigh:(id)sender {
    _m_btn_low.selected = false;
    _m_btn_middle.selected = false;
    _m_btn_high.selected = true;
    [_appDelegate changeWuhuaRate:50];
}
- (IBAction)ActionRateMiddle:(id)sender {
    _m_btn_low.selected = false;
    _m_btn_middle.selected = true;
    _m_btn_high.selected = false;
     [_appDelegate changeWuhuaRate:40];
}
- (IBAction)ActionRateLow:(id)sender {
    _m_btn_low.selected = true;
    _m_btn_middle.selected = false;
    _m_btn_high.selected = false;
    [_appDelegate changeWuhuaRate:33];
}

@end

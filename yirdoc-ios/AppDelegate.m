//
//  AppDelegate.m
//  yirdoc-ios
//
//  Created by 高存彬 on 2020/4/8.
//  Copyright © 2020 yirdoc. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <CBPeripheralDelegate, CBCentralManagerDelegate>
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBCharacteristic *wuhuaCharacteristic;
@property (nonatomic, strong) CBCharacteristic *wuhuaReadCharacteristic;
@property (nonatomic, strong) CBCharacteristic *powerReadCharacteristic;
@property (nonatomic, strong) CBCharacteristic *intermediateTemperatureCharacteristic;
@property (nonatomic, strong) NSMutableArray *thermometers;
@property (nonatomic, strong) NSMutableArray *rssis;
@property (nonatomic, assign) BOOL automaticallyReconnect;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //////////////////////////////STATE/////////////////////////////
    self.gameState = malloc(sizeof(GameState));
    self.deviceStatus = malloc(sizeof(DeviceStatus));
    self.gameState->breathIn_interval = 0;
    self.gameState->totalTime = 0;
    self.gameState->round = 0;
    self.gameState->state = breathOutStop;
    self.gameState->start_time = [NSDate timeIntervalSinceReferenceDate];
    self.gameState->currentScore = 0;
    
    ///////////////////////////////BLE//////////////////////////////
    self.thermometers = [NSMutableArray array];
    self.rssis = [NSMutableArray array];
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self startScan];
//        });
    
    return YES;
}


#pragma mark - UISceneSession lifecycle
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

#pragma mark blueTooth
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    [self isLECapableHardware];
}

// Use CBCentralManager to check whether the current platform/hardware supports Bluetooth LE.
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    switch ([self.manager state]) {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            {
                state = @"Bluetooth is currently powered off.";
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"alertTitle", nil) preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"alertCancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                }];
                UIAlertAction *otherAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"alertOK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                }];
                [alertController addAction:cancelAction];
                [alertController addAction:otherAction];
                [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
            }
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
    }
    NSLog(@"Central manager state: %@", state);
    return FALSE;
}

// Request CBCentralManager to scan for peripherals
- (void) startScan
{
    NSLog(@"startScan");
    self.automaticallyReconnect = YES;
    NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:@"1830"]];
    [self.manager scanForPeripheralsWithServices:services options:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startConnect];
    });
}

// Request CBCentralManager to stop scanning for peripherals
- (void) stopScan
{
    [self.manager stopScan];
}

- (void) disconnect
{
    self.automaticallyReconnect = YES;
    if (self.peripheral) {
//        [self.manager retrieveConnectedPeripherals];
        [self.manager retrieveConnectedPeripheralsWithServices:nil];
    }
}

- (void) centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    for (CBPeripheral *peripheral in peripherals) {
        NSLog(@"canceling connection to %@", peripheral);
        [self.manager cancelPeripheralConnection:peripheral];
    }
}

- (void) connectToPeripheral:(CBPeripheral *) peripheral {
    [self stopScan];
//    self.peripheral = peripheral;
//    [self.peripheral setDelegate:self];
    NSLog(@"connecting...");
    [self.manager connectPeripheral:peripheral
                            options:[NSDictionary dictionaryWithObject:
                                     [NSNumber numberWithBool:YES]
                                                                forKey:
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (void) startConnect{
     //[self connectToPeripheral:peripheral];
    NSNumber* max = [NSNumber numberWithInt:-200];
    NSNumber* min = [NSNumber numberWithInt:0];
    int index = 0;
    NSLog(@"startConnect");
    for(int i=0; i<self.rssis.count; i++)
    {
        
        NSComparisonResult r1 = [min compare:self.rssis[i]];
        NSComparisonResult r2 = [max compare:self.rssis[i]];
        
        if(r1==NSOrderedDescending){
            if(r2==NSOrderedAscending){
                max = self.rssis[i];
                index = i;
            }
        }
        
    }
    
    NSLog(@"startConnect: index is %d", index);
    if(self.thermometers.count>index)
    {
        CBPeripheral* peripheral = self.thermometers[index];
        [self connectToPeripheral:peripheral];
    }
    
}

// Invoked when the central discovers peripheral while scanning.
- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
    NSLog(@"RSSI %@", RSSI);
    
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"thermometers"];
    if(![self.thermometers containsObject:peripheral]){
        //[peripherals addObject:peripheral];
        [self.thermometers addObject:peripheral];
        [self.rssis addObject:RSSI];
    }
    
    
    //[self connectToPeripheral:peripheral];
    
    // Retrieve already known devices
    //  [self.manager retrievePeripherals:[NSArray arrayWithObject:(id)peripheral.UUID]];
}

// Invoked when the central manager retrieves the list of known peripherals.
// Automatically connect to first known peripheral
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", (unsigned long)[peripherals count], peripherals);
}

// Invoked when a connection is succesfully created with the peripheral.
// Discover available services on the peripheral
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCONNECTNotificationIdentifier object:nil userInfo:nil];

    NSLog(@"connected");
    self.peripheral = peripheral;
    [self.peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

// Invoked when an existing connection with the peripheral is torn down.
// Reset local variables
- (void) centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDISCONNECTNotificationIdentifier object:nil userInfo:nil];

    NSLog(@"centralManager:%@ didDisconnectPeripheral:%@ error:%@", central, peripheral, error);
    self.endTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    if (self.endTimeInterval > self.statTimeInterval) {
        self.totalTimeInterval = self.totalTimeInterval + self.endTimeInterval - self.statTimeInterval;
    }
    if (self.peripheral) {
        [self.peripheral setDelegate:nil];
        self.peripheral = nil;
    }
    if (self.automaticallyReconnect) {
        [self startScan];
    }
    
}

// Invoked when the central manager fails to create a connection with the peripheral.
- (void) centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", peripheral, [error localizedDescription]);
    if (self.peripheral) {
        [self.peripheral setDelegate:nil];
        self.peripheral = nil;
    }
}

#pragma mark - CBPeripheral delegate methods

// Invoked upon completion of a -[discoverServices:] request.
// Discover available characteristics on interested services
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *aService in peripheral.services) {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        /* Thermometer Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"1830"]]) {
            [peripheral discoverCharacteristics:nil forService:aService];
        }
        
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180f"]]) {
            [peripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* Device Information Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) {
            [peripheral discoverCharacteristics:nil forService:aService];
        }
        
        //        /* GAP (Generic Access Profile) for Device Name */
        //        if ([aService.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]]) {
        //            [peripheral discoverCharacteristics:nil forService:aService];
        //        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"peripheral:didDiscoverCharacteristicsForService:%@", service.UUID.data);
    
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@",
              service.UUID, [error localizedDescription]);
        return;
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:@"1830"]])
        //0002~0005
        //02: breath detection
        //03: power off signal
        //04: write control signal, such as adjust atomizer rate
        //05: read control signal, the first byte is atomizer rate
    {
        for (CBCharacteristic * characteristic in service.characteristics)
        {
            NSLog(@"discovered characteristic %@", characteristic.UUID);
            /* Set indication on Breath detection notification measurement */
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0002"]])
            {
                self.wuhuaCharacteristic = characteristic;
                [self.peripheral setNotifyValue:YES forCharacteristic:self.wuhuaCharacteristic];
                NSLog(@"Found Breath Detection Characteristic");
                self.statTimeInterval = [NSDate timeIntervalSinceReferenceDate];
            }
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003"]])
            {
                NSLog(@"Found Power Off Characteristic");
            }
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0005"]])
            {
                NSLog(@"Found Atomizer Rate Read Characteristic");
                self.wuhuaReadCharacteristic = characteristic;
//                NSData *data = characteristic.value;
//                //int value = *(int*)([data bytes]);
////                int value = *(int*)([data bytes]);
////                self.deviceStatus->wuhuaRate = value;
//                NSLog(@"value HEX string: %@", [data description]);
                [self readWuhuaRate];
            }
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0004"]])
            {
                self.wuhuaCharacteristic = characteristic;
                [self.peripheral setNotifyValue:YES forCharacteristic:self.wuhuaCharacteristic];
                
                NSLog(@"Found Atomizer Rate Control Notification Characteristic");
            }
            
            
            /* Set notification on intermediate temperature measurement */
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A1E"]])
            {
                self.intermediateTemperatureCharacteristic = characteristic;
                NSLog(@"Found an Intermediate Temperature Measurement Characteristic");
                [self.peripheral setNotifyValue:YES forCharacteristic:self.intermediateTemperatureCharacteristic];
            }
            /* Write value to measurement interval characteristic */
            if( [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A24"]])
            {
                uint16_t val = 2;
                NSData * valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
                [self.peripheral writeValue:valData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                NSLog(@"Found a Temperature Measurement Interval Characteristic - Write interval value");
            }
        }
    }
    
    else if([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]])
    {
        for (CBCharacteristic * characteristic in service.characteristics)
        {
            NSLog(@"discovered 180A characteristic %@", characteristic.UUID);
            /* Read manufacturer name */
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]])
            {
                [self.peripheral readValueForCharacteristic:characteristic];
                NSLog(@"Found a Device Manufacturer Name Characteristic - Read manufacturer name");
            }
            
            else {
                [self.peripheral readValueForCharacteristic:characteristic];
                
            }
        }
    }else if([service.UUID isEqual:[CBUUID UUIDWithString:@"180f"]]){
        for (CBCharacteristic * characteristic in service.characteristics)
        {
            [self.peripheral readValueForCharacteristic:characteristic];
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A19"]])
            {
                NSLog(@"init phase: 2A19 thing happening");
                self.powerReadCharacteristic = characteristic;
            }
            
            NSLog(@"Found a Device BATTERY INFO");
        }
        
    }
    
    //    else if ( [service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
    //    {
    //        for (CBCharacteristic *characteristic in service.characteristics)
    //        {
    //            NSLog(@"discovered generic characteristic %@", characteristic.UUID);
    //
    ////            /* Read device name */
    ////            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
    ////            {
    ////                //  [self.peripheral readValueForCharacteristic:characteristic];
    ////                //  NSLog(@"Found a Device Name Characteristic - Read device name");
    ////            }
    //        }
    //    }
    
    else {
        NSLog(@"unknown service discovery %@", service.UUID);
        
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error updating value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    // 01 ff 63
    // 吹99 吸入 1 停止255
    /* Updated value for temperature measurement received */
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0002"]])
    {
//        NSString *thing = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSData *data = characteristic.value;
        int value = *(int*)([data bytes]);
        switch (value) {
            case 1:
                [[NSNotificationCenter defaultCenter] postNotificationName:kINNotificationIdentifier object:nil userInfo:nil];

                self.gameState->start_time = [NSDate timeIntervalSinceReferenceDate];

                if (self.gameState->state == breathOutStop || self.gameState->state == breathOut) {
                    self.gameState->breathIn_interval = 0;
                } else {
                    self.gameState->breathIn_interval = self.gameState->breathIn_interval + ([NSDate timeIntervalSinceReferenceDate] - self.gameState->start_time);
                    self.gameState->totalTime = self.gameState->totalTime + ([NSDate timeIntervalSinceReferenceDate] - self.gameState->start_time);

                }
                self.gameState->state = breathIn;
                NSLog(@"Breath In");


                break;
                
            case 99:
                [[NSNotificationCenter defaultCenter] postNotificationName:kOUTNotificationIdentifier object:nil userInfo:nil];
                self.gameState->breathIn_interval = 0.0;
                self.gameState->state = breathOut;
                NSLog(@"Breath Out");


                break;
            case 255:
                if (self.gameState->state == breathIn || self.gameState->state == breathInStop){
                    self.gameState->breathIn_interval = self.gameState->breathIn_interval + ([NSDate timeIntervalSinceReferenceDate] - self.gameState->start_time);
                    self.gameState->totalTime = self.gameState->totalTime + ([NSDate timeIntervalSinceReferenceDate] - self.gameState->start_time);
                    

                    self.gameState->state = breathInStop;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSTOPNotificationIdentifier object:nil userInfo:nil];

                } else {
                    self.gameState->state = breathOutStop;
                }
                NSLog(@"Breath Stop");
                break;
                
            default:
                NSAssert(NO, @"Unkown Breath Actions");
                break;
                
                
        }
    
        NSLog(@"breathIn_interval = %f", self.gameState->breathIn_interval);
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0005"]]){
        NSLog(@"0005 thing happening");
        NSData *data = characteristic.value;
        NSLog(@"wuhuaRate value HEX string: %@", [data description]);
        Byte *testByte = (Byte*)([data bytes]);
        for(int i=0;i<[data length];i++)
        {
            NSLog(@"wuhuaRate update value: %d", testByte[i]);
        }
        
        self.deviceStatus->wuhuaRate = (int)testByte[0];
    }
    /* Value for manufacturer name received, is can be changed for different vendor */
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]])
    {
        NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Manufacturer Name = %@", manufacturerName);
        self.deviceStatus->manufacturerName = manufacturerName;
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A24"]])
    {
        NSLog(@"2A24 thing happening");
        NSString *thing = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"thing = %@", thing);
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A25"]])
    {
        NSLog(@"2A25 thing happening");
        
        NSString *SerialNum = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"SerialNum = %@", SerialNum);
        self.deviceStatus->serialnum = SerialNum;
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A26"]])
    {
        NSLog(@"2A26 thing happening");
        
        NSString *FirmwareVersion = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"FirmwareVersion = %@", FirmwareVersion);
        self.deviceStatus->firmversion = FirmwareVersion;
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A19"]])
    {
        NSLog(@"2A19 thing happening");
        NSData * updatedValue = characteristic.value;
        NSLog(@"length %lu", (unsigned long)[updatedValue length]);
        NSLog(@"value HEX string: %@", [updatedValue description]);
        int value = *(int*)([updatedValue bytes]);
        self.deviceStatus->powerValue = value;
        NSLog(@"value: %d", value);
    }
    else {
        NSLog(@"unknown thing happening: %@", characteristic.UUID);
        NSString *thing = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"thing = %@", thing);
    }
}

-(void)changeWuhuaRate:(uint8_t) val{
    Byte a[] = {1, val};
    NSData * valData = [NSData dataWithBytes:(void*)&a length:sizeof(a)];
    
    NSLog(@"changeWuhuaRate value HEX string: %@", [valData description]);
    [self.peripheral writeValue:valData forCharacteristic:self.wuhuaCharacteristic type:CBCharacteristicWriteWithoutResponse];
    
}

-(void)powerOff{
    Byte a[] = {3};
    NSData * valData = [NSData dataWithBytes:(void*)&a length:sizeof(a)];
    NSLog(@"powerOff value HEX string: %@", [valData description]);
    [self.peripheral writeValue:valData forCharacteristic:self.wuhuaCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

-(void)readWuhuaRate{
    if(self.wuhuaReadCharacteristic){
        [self.peripheral readValueForCharacteristic:self.wuhuaReadCharacteristic];
    }
}

-(void)readcurrentPower{
    if(self.powerReadCharacteristic){
        [self.peripheral readValueForCharacteristic:self.powerReadCharacteristic];
    }
}

@end

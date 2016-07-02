//
//  UARTPeripheral.h
//  nRF UART
//
//  Created by Ole Morten on 1/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol UARTPeripheralDelegate <NSObject>
- (void) didReceiveData:(NSString *) string;
- (void) peripheralReady;

- (void) didReadHardwareRevisionString:(NSString *) string;
- (void) didReadSoftwareRevisionString:(NSString *) string;
- (void) didReadFirmwareRevisionString:(NSString *) string;
- (void) didReadModelNumberString:(NSString *) string;
- (void) didReadSerialNumberString:(NSString *) string;
- (void) didReadManufacturerNameString:(NSString *) string;
@end


@interface UARTPeripheral : NSObject <CBPeripheralDelegate>
@property CBPeripheral *peripheral;
@property id<UARTPeripheralDelegate> delegate;
@property BOOL consoleLogging;

+ (CBUUID *) uartServiceUUID;
+ (CBUUID *) rxCharacteristicUUID;
+ (CBUUID *) txCharacteristicUUID;
+ (CBUUID *) deviceInformationServiceUUID;

- (UARTPeripheral *) initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<UARTPeripheralDelegate>) delegate;

- (void) writeString:(NSString *) string;

- (void) didConnect;
- (void) didDisconnect;
@end

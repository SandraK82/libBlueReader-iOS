//
//  UARTPeripheral.m
//  nRF UART
//
//  Created by Ole Morten on 1/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "UARTPeripheral.h"

@interface UARTPeripheral ()
@property CBService *uartService;
@property CBCharacteristic *rxCharacteristic;
@property CBCharacteristic *txCharacteristic;

@end

#define DebugLog(...) {if(self.consoleLogging)NSLog(__VA_ARGS__);}

@implementation UARTPeripheral
@synthesize peripheral = _peripheral;
@synthesize delegate = _delegate;

@synthesize uartService = _uartService;
@synthesize rxCharacteristic = _rxCharacteristic;
@synthesize txCharacteristic = _txCharacteristic;

+ (CBUUID *) uartServiceUUID
{
    return [CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"];
}

+ (CBUUID *) txCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"];
}

+ (CBUUID *) rxCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"];
}

+ (CBUUID *) deviceInformationServiceUUID
{
    return [CBUUID UUIDWithString:@"180A"];
}

+ (CBUUID *) manufacturerNameStringUUID
{
    return [CBUUID UUIDWithString:@"0x2A29"];
}
+ (CBUUID *) modelNumberStringUUID
{
    return [CBUUID UUIDWithString:@"0x2A24"];
}
+ (CBUUID *) serialNumberStringUUID
{
    return [CBUUID UUIDWithString:@"0x2A25"];
}
+ (CBUUID *) hardwareRevisionStringUUID
{
    return [CBUUID UUIDWithString:@"0x2A27"];
}
+ (CBUUID *) firmwareRevisionStringUUID
{
    return [CBUUID UUIDWithString:@"0x2A26"];
}
+ (CBUUID *) softwareRevisionStringUUID
{
    return [CBUUID UUIDWithString:@"0x2A28"];
}
+ (CBUUID *) batteryServiceUUID
{
    return [CBUUID UUIDWithString:@"0x180F"];
}
+ (CBUUID *) batteryLevelStringUUID
{
    return [CBUUID UUIDWithString:@"0x2A19"];
}
- (UARTPeripheral *) initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<UARTPeripheralDelegate>) delegate
{
    if (self = [super init])
    {
        _peripheral = peripheral;
        _peripheral.delegate = self;
        _delegate = delegate;
    }
    return self;
}

- (void) didConnect
{
    [_peripheral discoverServices:@[self.class.uartServiceUUID, self.class.deviceInformationServiceUUID]];
    DebugLog(@"Did start service discovery.");
}

- (void) didDisconnect
{

}

- (void) writeString:(NSString *) string
{
    NSData *data = [NSData dataWithBytes:string.UTF8String length:string.length];
    if ((self.txCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0)
    {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else if ((self.txCharacteristic.properties & CBCharacteristicPropertyWrite) != 0)
    {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        DebugLog(@"No write property on TX characteristic, %lu.", (unsigned long)self.txCharacteristic.properties);
    }
}

- (void) writeRawData:(NSData *) data
{

}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        DebugLog(@"Error discovering services: %@", error);
        return;
    }

    for (CBService *s in [peripheral services])
    {
        if ([s.UUID isEqual:self.class.uartServiceUUID])
        {
            DebugLog(@"Found correct service");
            self.uartService = s;

            [self.peripheral discoverCharacteristics:@[self.class.txCharacteristicUUID, self.class.rxCharacteristicUUID] forService:self.uartService];
        }
        else if ([s.UUID isEqual:self.class.deviceInformationServiceUUID])
        {
            [self.peripheral discoverCharacteristics:
             @[self.class.hardwareRevisionStringUUID,
               self.class.softwareRevisionStringUUID,
               self.class.modelNumberStringUUID,
               self.class.manufacturerNameStringUUID,
               self.class.serialNumberStringUUID,
               self.class.firmwareRevisionStringUUID]
                                          forService:s];
        }
        else if ([s.UUID isEqual:self.class.batteryServiceUUID])
        {
            [self.peripheral discoverCharacteristics:
             @[self.class.batteryLevelStringUUID]
                                          forService:s];

        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        DebugLog(@"Error discovering characteristics: %@", error);
        return;
    }

    for (CBCharacteristic *c in [service characteristics])
    {
        if ([c.UUID isEqual:self.class.rxCharacteristicUUID])
        {
            DebugLog(@"Found RX characteristic");
            self.rxCharacteristic = c;

            [self.peripheral setNotifyValue:YES forCharacteristic:self.rxCharacteristic];
        }
        else if ([c.UUID isEqual:self.class.txCharacteristicUUID])
        {
            DebugLog(@"Found TX characteristic");
            self.txCharacteristic = c;
        }
        else if ([c.UUID isEqual:self.class.hardwareRevisionStringUUID])
        {
            DebugLog(@"Found Hardware Revision String characteristic");
            [self.peripheral readValueForCharacteristic:c];
        }
        else if ([c.UUID isEqual:self.class.softwareRevisionStringUUID])
        {
            DebugLog(@"Found Software Revision String characteristic");
            [self.peripheral readValueForCharacteristic:c];
        }
        else if ([c.UUID isEqual:self.class.modelNumberStringUUID])
        {
            DebugLog(@"Found Model Number String characteristic");
            [self.peripheral readValueForCharacteristic:c];
        }
        else if ([c.UUID isEqual:self.class.manufacturerNameStringUUID])
        {
            DebugLog(@"Found Manufacturer Name String characteristic");
            [self.peripheral readValueForCharacteristic:c];
        }
        else if ([c.UUID isEqual:self.class.serialNumberStringUUID])
        {
            DebugLog(@"Found Serial Number String characteristic");
            [self.peripheral readValueForCharacteristic:c];
        }
        else if ([c.UUID isEqual:self.class.firmwareRevisionStringUUID])
        {
            DebugLog(@"Found Firmware Revision String characteristic");
            [self.peripheral readValueForCharacteristic:c];
        }

    }

    if(self.txCharacteristic && self.rxCharacteristic)
    {
        [self.delegate peripheralReady];
    }
}

/*- (NSString*) readCharacteristocValueAsHex:(NSData*)data
{
    NSString *string = @"";
    const uint8_t *bytes = data.bytes;
    for (int i = 0; i < data.length; i++)
    {
        DebugLog(@"%x", bytes[i]);
        string = [string stringByAppendingFormat:@"0x%02x, ", bytes[i]];
    }
    return string;
}*/
- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        DebugLog(@"Error receiving notification for characteristic %@: %@", characteristic, error);
        return;
    }

    DebugLog(@"Received data on a characteristic.");

    if (characteristic == self.rxCharacteristic)
    {

        NSString *string = [NSString stringWithUTF8String:[[characteristic value] bytes]];
        [self.delegate didReceiveData:string];
    }
    else if ([characteristic.UUID isEqual:self.class.hardwareRevisionStringUUID])
    {
        NSString* hwRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

        [self.delegate didReadHardwareRevisionString:hwRevision];
    }
    else if ([characteristic.UUID isEqual:self.class.softwareRevisionStringUUID])
    {
        NSString* softwareRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

        [self.delegate didReadSoftwareRevisionString:softwareRevision];
    }
    else if ([characteristic.UUID isEqual:self.class.firmwareRevisionStringUUID])
    {
        NSString* firmwareRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

        [self.delegate didReadFirmwareRevisionString:firmwareRevision];
    }
    else if ([characteristic.UUID isEqual:self.class.modelNumberStringUUID])
    {
        NSString* modelNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

        [self.delegate didReadModelNumberString:modelNumber];
    }
    else if ([characteristic.UUID isEqual:self.class.serialNumberStringUUID])
    {
        NSString* serialNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

        [self.delegate didReadSerialNumberString:serialNumber];
    }
    else if ([characteristic.UUID isEqual:self.class.manufacturerNameStringUUID])
    {
        NSString* manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        
        [self.delegate didReadManufacturerNameString:manufacturerName];
    }
}
@end
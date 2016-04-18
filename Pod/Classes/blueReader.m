//
//  blueReader.m
//  blueStyle
//
//  Created by fishermen21 on 12.04.16.
//  Copyright © 2016 Softwarehaus Kassel GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "blueReader.h"
#include "UARTPeripheral.h"


#define DebugLog(...) {if(self.consoleLogging)NSLog(__VA_ARGS__);}

@interface BlueReader () <UARTPeripheralDelegate,CBCentralManagerDelegate>
@property CBCentralManager *cm;
@property UARTPeripheral *currentPeripheral;
@property NSMutableDictionary* peripherals;
@property BlueReaderStatus readerStatus;
@property NSMutableArray* cmds;
@property BOOL handlingCmd;
@property NSString* incompleteAnswer;
@end

@implementation BlueReader

-(id) initWithDelegate:(id<BlueReaderDelegate>)delegate
{
    if(self = [super init])
    {
        self.consoleLogging = NO;
/*#ifdef DEBUG
        self.consoleLogging = YES;
#endif*/
        self.delegate = delegate;
        self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

- (void) setConsoleLogging:(BOOL)consoleLogging
{
    if(self.currentPeripheral)
    {
        self.currentPeripheral.consoleLogging = consoleLogging;
    }
    _consoleLogging = consoleLogging;
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch(central.state)
    {
        case CBCentralManagerStateUnknown:
            DebugLog(@"state of CBCentralManager changed to CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            DebugLog(@"state of CBCentralManager changed to CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            DebugLog(@"state of CBCentralManager changed to CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            DebugLog(@"state of CBCentralManager changed to CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            DebugLog(@"state of CBCentralManager changed to CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            DebugLog(@"state of CBCentralManager changed to CBCentralManagerStatePoweredOn");

            if(self.state == SHOULD_SCANNING)
            {
                [self startScanningForReader];
            }

            break;
    }
}

-(void) startScanningForReader
{
    self.peripherals = [NSMutableDictionary new];
    if(self.cm.state == CBCentralManagerStatePoweredOn)
    {
        DebugLog(@"started scanning");
        self.state = SCANNING;
        [self.cm scanForPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
    }
    else
    {
        DebugLog(@"scanning not possible, waiting for CBCentralManager to power on");
        self.state = SHOULD_SCANNING;
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    DebugLog(@"Did discover peripheral %@ and data %@", peripheral.name, advertisementData);

    [self.peripherals setObject:peripheral forKey:peripheral.name];

    [self.delegate blueReaderFound:peripheral.name];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didConnect];
    }
    self.state = CONNECTED;
}

-(void) peripheralReady
{
    self.cmds = [NSMutableArray new];
    self.handlingCmd = NO;
    self.readerStatus = UNKNOWN;

    [self.delegate blueReaderOpenedConnection:self.currentPeripheral.peripheral.name];

    if ([self.delegate respondsToSelector:@selector(blueReaderChangedStatus:)]) {
        [self.delegate blueReaderChangedStatus:self.readerStatus];
    }
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    DebugLog(@"Did disconnect peripheral %@", peripheral.name);

    self.state = IDLE;

    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didDisconnect];
        [self.delegate blueReaderClosedConnection:peripheral.name];
        self.currentPeripheral = nil;
        self.cmds = nil;
        self.handlingCmd = NO;
        self.readerStatus = UNKNOWN;
    }
}
-(void) stopScanningForReader
{
    [self.cm stopScan];
    if(self.state == SCANNING || self.state == SHOULD_SCANNING)
    {
        self.state = IDLE;
    }
}

-(void) openConnection:(NSString*) blueReader
{
    CBPeripheral* peripheral = [self.peripherals objectForKey:blueReader];
    if(peripheral)
    {
        self.currentPeripheral = [[UARTPeripheral alloc] initWithPeripheral:peripheral delegate:self];
        self.currentPeripheral.consoleLogging = self.consoleLogging;
        
        [self.cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
    }
}
-(void) closeConnection
{
    if(self.currentPeripheral.peripheral)
    {
        [self.cm cancelPeripheralConnection:self.currentPeripheral.peripheral];
    }
}

-(BOOL) wake
{
    switch(self.readerStatus)
    {
        case UNKNOWN:
            [self.cmds addObject:@"w"];
            break;
        case READY_FOR_TAG:
        case ANSWERING:
            return YES;
    }
    [self handleCmd];
    return NO;
}
-(void) reset
{
    DebugLog(@"issuing reset");
    self.cmds = [NSMutableArray new];
    [self.cmds addObject:@"w"];
    [self.cmds addObject:@"r"];
    [self.cmds addObject:@"w"];
    self.handlingCmd = NO;
    [self handleCmd];
}
-(BOOL) readyReader
{
    switch(self.readerStatus)
    {
        case UNKNOWN:
            [self reset];
        case ANSWERING:
            [self.cmds addObject:@"p"];
            break;
        case READY_FOR_TAG:
            return YES;
    }
    [self handleCmd];
    return NO;
}
-(void) hybernate
{
    switch(self.readerStatus)
    {
        case UNKNOWN:
            [self wake];
        case ANSWERING:
        case READY_FOR_TAG:
            [self.cmds addObject:@"h"];
            break;
    }
    [self handleCmd];
}
-(void) readTag
{
    switch(self.readerStatus)
    {
        case UNKNOWN:
        case ANSWERING:
            [self readyReader];
        case READY_FOR_TAG:
            [self.cmds addObject:@"t"];
            break;
    }
    [self handleCmd];
}
-(void) readAddress:(uint8_t)adr
{
    switch(self.readerStatus)
    {
        case UNKNOWN:
        case ANSWERING:
            [self readyReader];
        case READY_FOR_TAG:
            [self.cmds addObject:[NSString stringWithFormat:@"d:%#04x",adr]];
            break;
    }
    [self handleCmd];
}
-(void) identifyReader
{
    switch(self.readerStatus)
    {
        case UNKNOWN:
            [self wake];
        case ANSWERING:
        case READY_FOR_TAG:
            [self.cmds addObject:@"i"];
            break;
    }
    [self handleCmd];
}

-(void) handleCmd
{
    if(self.handlingCmd)
    {
        DebugLog(@"already handling cmd %@",[self.cmds objectAtIndex:0]);
    }
    else if([self.cmds count] == 0)
    {
        DebugLog(@"nothing to do handle");
    }
    else
    {
        DebugLog(@"having cmds: %@",[self.cmds description]);
        NSString* firstCMD = [self.cmds objectAtIndex:0];
        [self.currentPeripheral writeString:firstCMD];
        self.handlingCmd = YES;
    }
}

/*
 -(void) blueReaderIdentified:(NSString*) blueReaderData error:(NSError*)error;

 -(void) blueReaderFoundTag:(NSData*)tag error:(NSError*)error;
 -(void) blueReaderGotData:(uint8_t)adr data:(NSData*)data error:(NSError*)error;

 -(void) blueReaderChangedStatus:(BlueReaderStatus)status;
 */

-(void) nextCMD
{
    if([self.cmds count])
    {
        [self.cmds removeObjectAtIndex:0];
    }
    self.handlingCmd = NO;
    [self handleCmd];
}

-(void) didReceiveData:(NSString *)string
{
    if([string rangeOfString:@"!"].length==0)
    {
        if(self.incompleteAnswer)
        {
            self.incompleteAnswer = [NSString stringWithFormat:@"%@%@",self.incompleteAnswer,string];
        }
        else
        {
            self.incompleteAnswer = string;
        }
        DebugLog(@"found incomplete: %@",self.incompleteAnswer);
        return;
    }
    else if(self.incompleteAnswer)
    {
        string = [NSString stringWithFormat:@"%@%@",self.incompleteAnswer,string];
        self.incompleteAnswer = nil;
    }
    DebugLog(@"got read result: \"%@\"",string);
    BOOL foundStart = NO;
    BOOL isOK = NO;
    char cmd = 0;

    NSMutableArray *parameters = [NSMutableArray new];
    NSMutableString* currentParameter = nil;

    for(int i = 0; i < [string length];i++)
    {
        switch ([string characterAtIndex:i]) {
            case '+':
                if(!foundStart)
                {
                    foundStart = YES;
                    isOK = YES;
                }
                break;
            case '-':
                if(!foundStart)
                {
                    foundStart = YES;
                    isOK = NO;
                }
                break;
            case '!':
                if(i+1 != [string length])
                {
                    string = [string substringFromIndex:i+1];
                }
                else
                {
                    string = nil;
                }
                if(foundStart && cmd)
                {
                    NSString *s = ([parameters count] ? [parameters objectAtIndex:0] : currentParameter );

                    DebugLog(@"ready");
                    if(cmd=='d')
                    {
                        if(isOK)
                        {
                            //Send data
                            NSMutableData * data = [NSMutableData new];
                            for(int i = 0; i < [s length];i+=2)
                            {
                                Byte b = [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:i]]].location;
                                b = b << 4;
                                b = b | [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:i+1]]].location;
                                [data appendBytes:&b length:1];
                            }
                            uint16_t adr = [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[[self.cmds objectAtIndex:0] characterAtIndex:4]]].location << 4;
                            adr = adr | [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[[self.cmds objectAtIndex:0] characterAtIndex:5]]].location;

                            [self.delegate blueReaderGotData:adr data:data error:nil];
                        }
                        else
                        {
                            Byte e = [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:0]]].location;
                            e = e << 4;
                            e = e | [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:1]]].location;

                            Byte adr = [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[[self.cmds objectAtIndex:0] characterAtIndex:5]]].location;
                            adr = adr << 4;
                            adr = adr | [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[[self.cmds objectAtIndex:0] characterAtIndex:5]]].location;

                            [self.delegate blueReaderGotData:adr data:nil error:[NSError errorWithDomain:@"unable to read" code:e userInfo:nil]];
                        }
                    }
                    else if(cmd=='t')
                    {
                        if(isOK)
                        {
                            //Send data
                            NSMutableData * data = [NSMutableData new];
                            for(int i = 0; i < [s length];i+=2)
                            {
                                Byte b = [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:i]]].location;
                                b = b << 4;
                                b = b | [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:i+1]]].location;
                                [data appendBytes:&b length:1];
                            }
                            [self.delegate blueReaderFoundTag:data error:nil];
                        }
                        else
                        {
                            Byte e = 0;
                            if(s)
                            {
                                Byte e = [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:0]]].location;
                                e = e << 4;
                                e = e | [@"0123456789abcdef" rangeOfString:[NSString stringWithFormat:@"%c",[s characterAtIndex:1]]].location;
                            }
                            [self.delegate blueReaderFoundTag:nil error:[NSError errorWithDomain:@"no tag" code:e userInfo:nil]];
                        }
                    }
                    else
                    {
                        //update state
                        switch(cmd)
                        {
                            case '?':
                            {
                                if(s)
                                {
                                    switch ([s intValue]) {
                                        case 0:
                                            self.readerStatus = UNKNOWN;
                                            break;
                                        case 1:
                                            self.readerStatus = ANSWERING;
                                            break;
                                        case 2:
                                            self.readerStatus = READY_FOR_TAG;
                                            break;
                                            
                                        default:
                                            self.readerStatus = UNKNOWN;
                                    }
                                    if([self.delegate respondsToSelector:@selector(blueReaderChangedStatus:)])
                                    {
                                        [self.delegate blueReaderChangedStatus:self.readerStatus];
                                    }
                                }
                            }
                                break;
                            default:
                                if(isOK)
                                {
                                    if(cmd=='p')
                                    {
                                        self.readerStatus = READY_FOR_TAG;
                                        if([self.delegate respondsToSelector:@selector(blueReaderChangedStatus:)])
                                        {
                                            [self.delegate blueReaderChangedStatus:self.readerStatus];
                                        }
                                    }
                                    else if(cmd=='w')
                                    {
                                        self.readerStatus = ANSWERING;
                                        if([self.delegate respondsToSelector:@selector(blueReaderChangedStatus:)])
                                        {
                                            [self.delegate blueReaderChangedStatus:self.readerStatus];
                                        }
                                    }
                                    else if(cmd=='i')
                                    {
                                        [self.delegate blueReaderIdentified:s error:nil];
                                    }
                                    else if(cmd=='h')
                                    {
                                        self.readerStatus = UNKNOWN;
                                        if([self.delegate respondsToSelector:@selector(blueReaderChangedStatus:)])
                                        {
                                            [self.delegate blueReaderChangedStatus:self.readerStatus];
                                        }
                                    }
                                }
                                else
                                {
                                    DebugLog(@"somethign wrong here!");

                                    [self.cmds addObject:@"?"];
                                }
                        }
                    }
                    break;
                }
            default:
                if(foundStart)
                {
                    if(!cmd)
                    {
                        cmd=[string characterAtIndex:i];
                        if(cmd == [[self.cmds objectAtIndex:0] characterAtIndex:0])
                        {
                            DebugLog(@"correct answer found :D");
                        }
                    }
                    else if(cmd && [string characterAtIndex:i] == ':')
                    {
                        if(currentParameter)
                        {
                            [parameters addObject:currentParameter];
                        }
                        currentParameter = [NSMutableString new];
                    }
                    else if(cmd && currentParameter)
                    {
                        [currentParameter appendFormat:@"%c",[string characterAtIndex:i] ];
                    }
                }
        }
    }
    if(string)
    {
        [self didReceiveData:string];
    }
    [self nextCMD];
}
@end
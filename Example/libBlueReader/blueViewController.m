//
//  blueViewController.m
//  libBlueReader
//
//  Created by Sandra Keßler on 04/13/2016.
//  Copyright (c) 2016 Sandra Keßler. All rights reserved.
//

#import "blueViewController.h"

@interface blueViewController ()
@property BlueReader* blueReader;
@property NSString* choosenReader;
@end

@implementation blueViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.blueReader = [[BlueReader alloc] initWithDelegate:self];
//    self.blueReader.consoleLogging = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewDidAppear:(BOOL)animated
{
    [self.blueReader startScanningForReader];
}
-(void) blueReaderFound:(NSString*) blueReader
{
    if(!self.choosenReader)
    {
        self.choosenReader = blueReader;
        [[self blueReader] openConnection:blueReader];

    }
}

-(void) blueReaderIdentified:(NSString*) blueReaderData error:(NSError*)error
{
    NSLog(@"found blueReader: %@",blueReaderData);
    [[self blueReader] readTag];
}

-(void) blueReaderGotData:(uint8_t)adr data:(NSData*)data error:(NSError*)error
{
    NSLog(@"got data from adr: %d with length %lu",adr,(unsigned long)[data length]);
    Byte *b = (Byte*)[data bytes];
    for(int i =0; i< [data length];i++)
    {
        NSLog(@"D[%d]: %#04x",i,b[i]);
    }
}
-(void) blueReaderOpenedConnection:(NSString*)blueReader
{
    NSLog(@"connected to: %@",blueReader);
    [[self blueReader] readyReader];
}
-(void) blueReaderClosedConnection:(NSString*)blueReader
{
    NSLog(@"closed connection to %@",blueReader);
}

-(void) blueReaderFoundTag:(NSData*)tag error:(NSError*)error
{
    if(tag)
    {
        Byte *b = (Byte*)[tag bytes];
        NSMutableString* tagI = [NSMutableString new];
        for(int i =0; i< [tag length];i++)
        {
            [tagI appendFormat:@"%02x ",b[i]];
        }
        NSLog(@"found an tag: %@",tagI);
        [[self blueReader] readAddress:0x10];
    }
    else
    {
        NSLog(@"found no tag!");
    }
}
-(void) blueReaderChangedStatus:(BlueReaderStatus)status
{
    NSLog(@"blueReader changed Status: %ld",(long)status);
    if(status == READY_FOR_TAG)
    {
        [[self blueReader] identifyReader];
    }
}

@end

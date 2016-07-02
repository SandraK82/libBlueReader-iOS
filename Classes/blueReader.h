//
//  blueReader.h
//  blueStyle
//
//  Created by fishermen21 on 12.04.16.
//  Copyright © 2016 Softwarehaus Kassel GmbH. All rights reserved.
//

#ifndef blueReader_h
#define blueReader_h

typedef NS_ENUM(NSInteger, BlueReaderStatus) {
    UNKNOWN,
    ANSWERING,
    READY_FOR_TAG
};

typedef enum
{
    IDLE = 0,
    SCANNING,
    SHOULD_SCANNING,
    CONNECTED,
} ConnectionState;


@protocol BlueReaderDelegate <NSObject>
-(void) blueReaderFound:(NSString*) blueReader;
-(void) blueReaderIdentified:(NSString*) blueReaderData error:(NSError*)error;

-(void) blueReaderFoundTag:(NSData*)tag error:(NSError*)error;
-(void) blueReaderGotData:(uint8_t)adr data:(NSData*)data error:(NSError*)error;

-(void) blueReaderOpenedConnection:(NSString*)blueReader;
-(void) blueReaderClosedConnection:(NSString*)blueReader;

@optional
-(void) blueReaderChangedStatus:(BlueReaderStatus)status;
@end

@interface BlueReader : NSObject

@property id<BlueReaderDelegate> delegate;
@property (nonatomic) BOOL consoleLogging;
@property ConnectionState state;


-(id) initWithDelegate:(id<BlueReaderDelegate>)delegate;

-(void) startScanningForReader;
-(void) stopScanningForReader;

-(void) openConnection:(NSString*) blueReader;
-(void) identifyReader;
-(void) closeConnection;

-(void) readTag;
-(void) readAddress:(uint8_t)adr;

-(BOOL) readyReader;
-(BOOL) wake;
-(void) hybernate;
-(void) startbeat:(int)beattime;
-(void) stopbeat;

@end
#endif /* blueReader_h */

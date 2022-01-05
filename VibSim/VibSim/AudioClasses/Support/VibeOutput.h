//
//  VibeOutput.h
//


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
#import <AudioUnit/AudioUnit.h>
#endif

#import "TPCircularBuffer.h"

@class VibeOutput;

@protocol VibeOutputDataSource <NSObject>

@optional

-(void)output:(VibeOutput*)output
callbackWithActionFlags:(AudioUnitRenderActionFlags*)ioActionFlags
  inTimeStamp:(const AudioTimeStamp*)inTimeStamp
  inBusNumber:(UInt32)inBusNumber
inNumberFrames:(UInt32)inNumberFrames
       ioData:(AudioBufferList*)ioData;


-(TPCircularBuffer*)outputShouldUseCircularBuffer:(VibeOutput *)output;


-(void)             output:(VibeOutput *)output
 shouldFillAudioBufferList:(AudioBufferList*)audioBufferList
        withNumberOfFrames:(UInt32)frames;

@end

@interface VibeOutput : NSObject

#pragma mark - Properties
@property (nonatomic,assign) id<VibeOutputDataSource>outputDataSource;

#pragma mark - Initializers

-(id)initWithDataSource:(id<VibeOutputDataSource>)dataSource;

-(id)         initWithDataSource:(id<VibeOutputDataSource>)dataSource
 withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;

#pragma mark - Class Initializers

+(VibeOutput*)outputWithDataSource:(id<VibeOutputDataSource>)dataSource;

+(VibeOutput*)outputWithDataSource:(id<VibeOutputDataSource>)dataSource
 withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;

#pragma mark - Singleton

+(VibeOutput*)sharedOutput;

#pragma mark - Events

-(void)startPlayback;

-(void)stopPlayback;

#pragma mark - Getters

-(AudioStreamBasicDescription)audioStreamBasicDescription;

-(BOOL)isPlaying;

#pragma mark - Setters

-(void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd;

@end

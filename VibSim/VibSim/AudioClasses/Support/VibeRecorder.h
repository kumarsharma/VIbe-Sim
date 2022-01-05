//
//  VibeRecorder.h
//


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface VibeRecorder : NSObject

#pragma mark - Initializers

-(VibeRecorder*)initWithDestinationURL:(NSURL*)url
                     andSourceFormat:(AudioStreamBasicDescription)sourceFormat;


#pragma mark - Class Initializers

+(VibeRecorder*)recorderWithDestinationURL:(NSURL*)url
                         andSourceFormat:(AudioStreamBasicDescription)sourceFormat;

#pragma mark - Class Methods

+(AudioStreamBasicDescription)defaultDestinationFormat;

+(NSString*)defaultDestinationFormatExtension;

#pragma mark - Getters

-(NSURL*)url;

#pragma mark - Events

-(void)appendDataFromBufferList:(AudioBufferList*)bufferList
                 withBufferSize:(UInt32)bufferSize;

-(void)closeAudioFile;

@end

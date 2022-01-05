//
//  VibedataInput.h
//


#import  <Foundation/Foundation.h>
#import  <AudioToolbox/AudioToolbox.h>
#import  "AEFloatConverter.h"
#import  "TargetConditionals.h"

@class VibeAudio;
@class VibedataInput;

#pragma mark - VibedataInputDelegate

@protocol VibedataInputDelegate <NSObject>

@optional

-(void)              microphone:(VibedataInput *)microphone
 hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;




-(void)    microphone:(VibedataInput*)microphone
     hasAudioReceived:(float**)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels;

-(void)    microphone:(VibedataInput*)microphone
        hasBufferList:(AudioBufferList*)bufferList
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels;

@end

#pragma mark - VibedataInput

@interface VibedataInput : NSObject


@property (nonatomic,assign) id<VibedataInputDelegate> microphoneDelegate;


@property (nonatomic,assign) BOOL microphoneOn;

#pragma mark - Initializers

-(VibedataInput*)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate;


-(VibedataInput*)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate
           withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;


-(VibedataInput*)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate
                          startsImmediately:(BOOL)startsImmediately;


-(VibedataInput*)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate
           withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
                         startsImmediately:(BOOL)startsImmediately;

#pragma mark - Class Initializers

+(VibedataInput*)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate;


+(VibedataInput*)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate
       withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription;


+(VibedataInput*)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate
                      startsImmediately:(BOOL)startsImmediately;


+(VibedataInput*)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate
       withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
                     startsImmediately:(BOOL)startsImmediately;

#pragma mark - Singleton

+(VibedataInput*)sharedMicrophone;

#pragma mark - Events

-(void)startFetchingAudio;


-(void)stopFetchingAudio;

#pragma mark - Getters

-(AudioStreamBasicDescription)audioStreamBasicDescription;

#pragma mark - Setters

-(void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd;
-(void) ChangeAUSR;
+ (int)getFlagConnected;

@end

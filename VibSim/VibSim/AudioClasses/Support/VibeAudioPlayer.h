//
//  VibeAudioPlayer.h
//


#import <Foundation/Foundation.h>
#import "TargetConditionals.h"

#import "VibeAudio.h"

#if TARGET_OS_IPHONE
  #import <AVFoundation/AVFoundation.h>
#elif TARGET_OS_MAC
#endif

@class VibeAudioPlayer;


@protocol VibeAudioPlayerDelegate <NSObject>

@optional

-(void)audioPlayer:(VibeAudioPlayer*)audioPlayer didResumePlaybackOnAudioFile:(VibeAudioFile*)audioFile;


-(void)audioPlayer:(VibeAudioPlayer*)audioPlayer didPausePlaybackOnAudioFile:(VibeAudioFile*)audioFile;


-(void)audioPlayer:(VibeAudioPlayer*)audioPlayer reachedEndOfAudioFile:(VibeAudioFile*)audioFile;


-(void)   audioPlayer:(VibeAudioPlayer*)audioPlayer
            readAudio:(float**)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
          inAudioFile:(VibeAudioFile*)audioFile;;

-(void)audioPlayer:(VibeAudioPlayer*)audioPlayer
   updatedPosition:(SInt64)framePosition
       inAudioFile:(VibeAudioFile*)audioFile;

@end


@interface VibeAudioPlayer : NSObject

#pragma mark - Properties

@property (nonatomic,assign) id<VibeAudioPlayerDelegate> audioPlayerDelegate;

@property (nonatomic,assign) BOOL shouldLoop;

#pragma mark - Initializers

-(VibeAudioPlayer*)initWithVibeAudioFile:(VibeAudioFile*)audioFile;


-(VibeAudioPlayer*)initWithVibeAudioFile:(VibeAudioFile*)audioFile
                        withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate;

-(VibeAudioPlayer*)initWithURL:(NSURL*)url;


-(VibeAudioPlayer*)initWithURL:(NSURL*)url
                withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate;


#pragma mark - Class Initializers

+(VibeAudioPlayer*)audioPlayerWithVibeAudioFile:(VibeAudioFile*)audioFile;


+(VibeAudioPlayer*)audioPlayerWithVibeAudioFile:(VibeAudioFile*)audioFile
                               withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate;


+(VibeAudioPlayer*)audioPlayerWithURL:(NSURL*)url;

+(VibeAudioPlayer*)audioPlayerWithURL:(NSURL*)url
                       withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate;

#pragma mark - Singleton

+(VibeAudioPlayer*)sharedAudioPlayer;

#pragma mark - Getters

-(VibeAudioFile*)audioFile;

-(float)currentTime;


-(BOOL)endOfFile;


-(SInt64)frameIndex;


-(BOOL)isPlaying;


-(VibeOutput*)output;


-(float)totalDuration;


-(SInt64)totalFrames;


-(NSURL*)url;

#pragma mark - Setters
-(void)setAudioFile:(VibeAudioFile*)audioFile;

-(void)setOutput:(VibeOutput*)output;

#pragma mark - Methods

-(void)play;


-(void)pause;


-(void)stop;


-(void)seekToFrame:(SInt64)frame;

@end

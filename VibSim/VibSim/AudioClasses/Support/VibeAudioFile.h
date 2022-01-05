//
// VibeAudioFile.h
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class VibeAudio;
@class VibeAudioFile;


@protocol VibeAudioFileDelegate <NSObject>

@optional

-(void)     audioFile:(VibeAudioFile*)audioFile
            readAudio:(float**)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels;

-(void)audioFile:(VibeAudioFile*)audioFile
 updatedPosition:(SInt64)framePosition;

@end


@interface VibeAudioFile : NSObject

#pragma mark - Blocks

typedef void (^WaveformDataCompletionBlock)(float *waveformData, UInt32 length);

#pragma mark - Properties

@property (nonatomic,assign) id<VibeAudioFileDelegate> audioFileDelegate;


@property (nonatomic,assign) UInt32 waveformResolution;

#pragma mark - Initializers

-(VibeAudioFile*)initWithURL:(NSURL*)url;


-(VibeAudioFile*)initWithURL:(NSURL*)url
               andDelegate:(id<VibeAudioFileDelegate>)delegate;

#pragma mark - Class Initializers

+(VibeAudioFile*)audioFileWithURL:(NSURL*)url;

+(VibeAudioFile*)audioFileWithURL:(NSURL*)url
                    andDelegate:(id<VibeAudioFileDelegate>)delegate;

#pragma mark - Class Methods

+(NSArray*)supportedAudioFileTypes;

#pragma mark - Events

-(void)readFrames:(UInt32)frames
  audioBufferList:(AudioBufferList*)audioBufferList
       bufferSize:(UInt32*)bufferSize
              eof:(BOOL*)eof;


-(void)seekToFrame:(SInt64)frame;

#pragma mark - Getters

-(AudioStreamBasicDescription)clientFormat;


-(AudioStreamBasicDescription)fileFormat;

-(SInt64)frameIndex;

-(Float32)totalDuration;

-(SInt64)totalFrames;

-(NSURL*)url;

#pragma mark - Helpers
-(BOOL)hasLoadedAudioData;

-(void)getWaveformDataWithCompletionBlock:(WaveformDataCompletionBlock)waveformDataCompletionBlock;

-(UInt32)minBuffersWithFrameRate:(UInt32)frameRate;


-(UInt32)recommendedDrawingFrameRate;

@end

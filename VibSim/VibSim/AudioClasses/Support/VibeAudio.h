//
// VibeAudio.h
//

#import <Foundation/Foundation.h>

#pragma mark - 3rd Party Utilties
#import "AEFloatConverter.h"
#import "TPCircularBuffer.h"

#pragma mark - Core Components
#import "VibeAudioFile.h"
#import "VibedataInput.h"
#import "VibeOutput.h"
#import "VibeRecorder.h"

#pragma mark - Extended Components
#import "VibeAudioPlayer.h"

extern int ExternFFTBandWidth;
extern int FmaxExtern;
extern int TWFgainExtern;
extern int SampRateExtern;
extern int BinMultiplier;
extern int nLinesExtern;
extern int AccVelExtern;
extern int WindowingExtern;
extern int flagFirstTimeRun;
extern int TouchesTWFxExtern;
extern double TWFdurationExtern;
extern int BackgroundExtern;
extern int TouchMarkerExtern;
extern double CalibrationExtern;
extern double MaxPeakAmplExtern;
extern double MaxPeakFreqExtern;
extern double FmaxLabelExtern;
extern int numberOfTimeMeasured;
extern int filterExtern;
extern int unitsAmpExtern;
extern int unitsFreqExtern;
extern float buffer1[];
extern int bufferSizeExt;
extern int flagLoadData;
extern int flagSaveData;
extern int flagLastBufferSize;
extern int flagLastSampRate;
extern int flagChangeBufferSize;
extern int TouchMarkerHarmonics;
extern int ManualMarkerExtern;
extern int ManualMarkerHarmonics;
extern int RPMmarkerExtern;
extern double rmsExtern;
extern double peakExtern;


@interface VibeAudio : NSObject


#pragma mark - AudioBufferList Utility
+(AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames
                                     numberOfChannels:(UInt32)channels
                                          interleaved:(BOOL)interleaved;

+(void)freeBufferList:(AudioBufferList*)bufferList;

#pragma mark - AudioStreamBasicDescription Utilties

+(AudioStreamBasicDescription)monoFloatFormatWithSampleRate:(float)sampleRate;


+(AudioStreamBasicDescription)monoCanonicalFormatWithSampleRate:(float)sampleRate;


+(AudioStreamBasicDescription)stereoCanonicalNonInterleavedFormatWithSampleRate:(float)sampleRate;

+(AudioStreamBasicDescription)stereoFloatInterleavedFormatWithSampleRate:(float)sampleRate;


+(AudioStreamBasicDescription)stereoFloatNonInterleavedFormatWithSampleRate:(float)sameRate;


+(void)printASBD:(AudioStreamBasicDescription)asbd;

+(void)setCanonicalAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd
                              numberOfChannels:(UInt32)nChannels
                                   interleaved:(BOOL)interleaved;

#pragma mark - Math Utilities

+(void)appendBufferAndShift:(float*)buffer
             withBufferSize:(int)bufferLength
            toScrollHistory:(float*)scrollHistory
      withScrollHistorySize:(int)scrollHistoryLength;

+(void)    appendValue:(float)value
       toScrollHistory:(float*)scrollHistory
 withScrollHistorySize:(int)scrollHistoryLength;

+(float)MAP:(float)value
    leftMin:(float)leftMin
    leftMax:(float)leftMax
   rightMin:(float)rightMin
   rightMax:(float)rightMax;

+(float)RMS:(float*)buffer
     length:(int)bufferSize;

+(float)PEAK:(float*)buffer
     length:(int)bufferSize;


+(float)SGN:(float)value;

#pragma mark - OSStatus Utility

+(void)checkResult:(OSStatus)result
         operation:(const char*)operation;

#pragma mark - Plot Utility
+(void)updateScrollHistory:(float**)scrollHistory
                withLength:(int)scrollHistoryLength
                   atIndex:(int*)index
                withBuffer:(float*)buffer
            withBufferSize:(int)bufferSize
      isResolutionChanging:(BOOL*)isChanging;

#pragma mark - TPCircularBuffer Utility
+(void)appendDataToCircularBuffer:(TPCircularBuffer*)circularBuffer
              fromAudioBufferList:(AudioBufferList*)audioBufferList;


+(void)circularBuffer:(TPCircularBuffer*)circularBuffer
             withSize:(int)size;


+(void)freeCircularBuffer:(TPCircularBuffer*)circularBuffer;

@end

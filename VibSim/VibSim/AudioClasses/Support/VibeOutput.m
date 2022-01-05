//
//  VibeOutput.m
//


#import "VibeOutput.h"

#import "VibeAudio.h"

/// Buses
static const AudioUnitScope   kVibeAudioMicrophoneOutputBus   = 0;

/// Flags
static const UInt32           kVibeAudioMicrophoneEnableFlag  = 1;
static const UInt32           kVibeAudioMicrophoneDisableFlag = 0;

@interface VibeOutput (){
  BOOL                        _customASBD;
  BOOL                        _isPlaying;
  AudioStreamBasicDescription _outputASBD;
  AudioUnit                   _outputUnit;
}
@end

@implementation VibeOutput
@synthesize outputDataSource = _outputDataSource;

static OSStatus OutputRenderCallback(void                        *inRefCon,
                                     AudioUnitRenderActionFlags  *ioActionFlags,
                                     const AudioTimeStamp        *inTimeStamp,
                                     UInt32                      inBusNumber,
                                     UInt32                      inNumberFrames,
                                     AudioBufferList             *ioData){
  
  
  VibeOutput *output = (__bridge VibeOutput*)inRefCon;
  if( [output.outputDataSource respondsToSelector:@selector(output:callbackWithActionFlags:inTimeStamp:inBusNumber:inNumberFrames:ioData:)] ){
    [output.outputDataSource output:output
            callbackWithActionFlags:ioActionFlags
                        inTimeStamp:inTimeStamp
                        inBusNumber:inBusNumber
                     inNumberFrames:inNumberFrames
                             ioData:ioData];
  }
  else if( [output.outputDataSource respondsToSelector:@selector(outputShouldUseCircularBuffer:)] ){
    
    TPCircularBuffer *circularBuffer = [output.outputDataSource outputShouldUseCircularBuffer:output];
    if( !circularBuffer ){
      AudioUnitSampleType *left  = (AudioUnitSampleType*)ioData->mBuffers[0].mData;
      AudioUnitSampleType *right = (AudioUnitSampleType*)ioData->mBuffers[1].mData;
      for(int i = 0; i < inNumberFrames; i++ ){
        left[  i ] = 0.0f;
        right[ i ] = 0.0f;
      }
      return noErr;
    };

    
    int32_t bytesToCopy = ioData->mBuffers[0].mDataByteSize;
    AudioSampleType *left  = (AudioSampleType*)ioData->mBuffers[0].mData;
    AudioSampleType *right = (AudioSampleType*)ioData->mBuffers[1].mData;
    
    int32_t availableBytes;
    AudioSampleType *buffer = TPCircularBufferTail(circularBuffer,&availableBytes);
    
    int32_t amount = MIN(bytesToCopy,availableBytes);
    memcpy( left,  buffer, amount );
    memcpy( right, buffer, amount );
    
    TPCircularBufferConsume(circularBuffer,amount);
    
  }
  else if( [output.outputDataSource respondsToSelector:@selector(output:shouldFillAudioBufferList:withNumberOfFrames:)] ) {
    [output.outputDataSource output:output
          shouldFillAudioBufferList:ioData
                 withNumberOfFrames:inNumberFrames];
  }
  
  return noErr;
}

#pragma mark - Initialization
-(id)init {
  self = [super init];
  if(self){
    [self _configureOutput];
  }
  return self;
}

-(id)initWithDataSource:(id<VibeOutputDataSource>)dataSource {
  self = [super init];
  if(self){
    self.outputDataSource = dataSource;
    [self _configureOutput];
  }
  return self;
}

-(id)         initWithDataSource:(id<VibeOutputDataSource>)dataSource
 withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
  self = [super init];
  if(self){
    _customASBD = YES;
    _outputASBD = audioStreamBasicDescription;
    self.outputDataSource = dataSource;
    [self _configureOutput];
  }
  return self;
}

#pragma mark - Class Initializers
+(VibeOutput*)outputWithDataSource:(id<VibeOutputDataSource>)dataSource {
  return [[VibeOutput alloc] initWithDataSource:dataSource];
}

+(VibeOutput *)outputWithDataSource:(id<VibeOutputDataSource>)dataSource
  withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
  return [[VibeOutput alloc] initWithDataSource:dataSource withAudioStreamBasicDescription:audioStreamBasicDescription];
}

#pragma mark - Singleton
+(VibeOutput*)sharedOutput {
  static VibeOutput *_sharedOutput = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedOutput = [[VibeOutput alloc] init];
  });
  return _sharedOutput;
}

#pragma mark - Audio Component Initialization
-(AudioComponentDescription)_getOutputAudioComponentDescription {
  AudioComponentDescription outputComponentDescription;
  outputComponentDescription.componentFlags        = 0;
  outputComponentDescription.componentFlagsMask    = 0;
  outputComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
  #if TARGET_OS_IPHONE
    outputComponentDescription.componentSubType      = kAudioUnitSubType_RemoteIO;
  #elif TARGET_OS_MAC
    outputComponentDescription.componentSubType      = kAudioUnitSubType_DefaultOutput;
  #endif
  outputComponentDescription.componentType         = kAudioUnitType_Output;
  return outputComponentDescription;
}

-(AudioComponent)_getOutputComponentWithAudioComponentDescription:(AudioComponentDescription)outputComponentDescription {
  // Try and find the component
  AudioComponent outputComponent = AudioComponentFindNext( NULL , &outputComponentDescription );
  NSAssert(outputComponent,@"Couldn't get input component unit!");
  return outputComponent;
}

-(void)_createNewInstanceForOutputComponent:(AudioComponent)outputComponent {
  //
  [VibeAudio checkResult:AudioComponentInstanceNew( outputComponent, &_outputUnit )
             operation:"Failed to open component for output unit"];
}

#pragma mark - Configure The Output Unit


#if TARGET_OS_IPHONE
-(void)_configureOutput {
  
  //
  AudioComponentDescription outputcd;
  outputcd.componentFlags        = 0;
  outputcd.componentFlagsMask    = 0;
  outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
  outputcd.componentSubType      = kAudioUnitSubType_RemoteIO;
  outputcd.componentType         = kAudioUnitType_Output;
  
  //
  AudioComponent comp = AudioComponentFindNext(NULL,&outputcd);
  [VibeAudio checkResult:AudioComponentInstanceNew(comp,&_outputUnit)
             operation:"Failed to get output unit"];
  
  UInt32           oneFlag = 1;
  AudioUnitElement bus0    = 0;
  [VibeAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                            kAudioOutputUnitProperty_EnableIO,
                                            kAudioUnitScope_Output,
                                            bus0,
                                            &oneFlag,
                                            sizeof(oneFlag))
             operation:"Failed to enable output unit"];
  
//  double hardwareSampleRate; changed to fix hardware sampling rate issue 08/31/21 YK
  Float64 hardwareSampleRate = 44100;
    
#if !(TARGET_IPHONE_SIMULATOR)
  UInt32 propSize = sizeof(hardwareSampleRate);
  [VibeAudio checkResult:AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                                               &propSize,
                                               &hardwareSampleRate)
             operation:"Could not get hardware sample rate"];
#endif
  
  if( !_customASBD ){
    _outputASBD = [VibeAudio stereoCanonicalNonInterleavedFormatWithSampleRate:hardwareSampleRate];
  }
  
  [VibeAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input,
                                            bus0,
                                            &_outputASBD,
                                            sizeof(_outputASBD))
             operation:"Couldn't set the ASBD for input scope/bos 0"];
  
  //
  AURenderCallbackStruct input;
  input.inputProc = OutputRenderCallback;
  input.inputProcRefCon = (__bridge void *)self;
  [VibeAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                            kAudioUnitProperty_SetRenderCallback,
                                            kAudioUnitScope_Input,
                                            bus0,
                                            &input,
                                            sizeof(input))
             operation:"Failed to set the render callback on the output unit"];
  
  
  [VibeAudio checkResult:AudioUnitInitialize(_outputUnit)
             operation:"Couldn't initialize output unit"];
  
  
}
#elif TARGET_OS_MAC
-(void)_configureOutput {
  
  //
  AudioComponentDescription outputcd;
  outputcd.componentType         = kAudioUnitType_Output;
  outputcd.componentSubType      = kAudioUnitSubType_DefaultOutput;
  outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
  
  //
  AudioComponent comp = AudioComponentFindNext(NULL,&outputcd);
  if( comp == NULL ){
    NSLog(@"Failed to get output unit");
    exit(-1);
  }
  [VibeAudio checkResult:AudioComponentInstanceNew(comp,&_outputUnit)
             operation:"Failed to open component for output unit"];

  
  if( !_customASBD ){
    _outputASBD = [VibeAudio stereoCanonicalNonInterleavedFormatWithSampleRate:44100];
  }
  
  [VibeAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input,
                                            0,
                                            &_outputASBD,
                                            sizeof(_outputASBD))
             operation:"Couldn't set the ASBD for input scope/bos 0"];
  
  
  AURenderCallbackStruct input;
  input.inputProc = OutputRenderCallback;
  input.inputProcRefCon = (__bridge void *)(self);
  [VibeAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                            kAudioUnitProperty_SetRenderCallback,
                                            kAudioUnitScope_Input,
                                            0,
                                            &input,
                                            sizeof(input))
             operation:"Failed to set the render callback on the output unit"];
  
  
  [VibeAudio checkResult:AudioUnitInitialize(_outputUnit)
             operation:"Couldn't initialize output unit"];
  
}
#endif

#pragma mark - Events
-(void)startPlayback {
  if( !_isPlaying ){
    [VibeAudio checkResult:AudioOutputUnitStart(_outputUnit)
               operation:"Failed to start output unit"];
    _isPlaying = YES;
  }
}

-(void)stopPlayback {
  if( _isPlaying ){
    [VibeAudio checkResult:AudioOutputUnitStop(_outputUnit)
               operation:"Failed to stop output unit"];
    _isPlaying = NO;
  }
}

#pragma mark - Getters
-(AudioStreamBasicDescription)audioStreamBasicDescription {
  return _outputASBD;
}

-(BOOL)isPlaying {
  return _isPlaying;
}

#pragma mark - Setters
-(void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
  BOOL wasPlaying = NO;
  if( self.isPlaying ){
    [self stopPlayback];
    wasPlaying = YES;
  }
  _customASBD = YES;
  _outputASBD = asbd;
  [VibeAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input,
                                            0,
                                            &_outputASBD,
                                            sizeof(_outputASBD))
             operation:"Couldn't set the ASBD for input scope/bos 0"];
  if( wasPlaying )
  {
    [self startPlayback];
  }
}

-(void)dealloc {
  [VibeAudio checkResult:AudioOutputUnitStop(_outputUnit)
             operation:"Failed to uninitialize output unit"];
  [VibeAudio checkResult:AudioUnitUninitialize(_outputUnit)
             operation:"Failed to uninitialize output unit"];
  [VibeAudio checkResult:AudioComponentInstanceDispose(_outputUnit)
             operation:"Failed to uninitialize output unit"];
}

@end

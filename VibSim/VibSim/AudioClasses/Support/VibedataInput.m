//
//  VibedataInput.m
//


#import "VibedataInput.h"
#import "VibSim-Swift.h"

#ifndef MAC_OS_X_VERSION_10_7
#include <CoreServices/CoreServices.h>
#endif

#import "VibeAudio.h"
//#import "AppDelegate.h"

static const AudioUnitScope kVibeAudioMicrophoneInputBus  = 1;
static const AudioUnitScope kVibeAudioMicrophoneOutputBus = 0;

#if TARGET_OS_IPHONE
static const UInt32 kVibeAudioMicrophoneDisableFlag = 1;
#elif TARGET_OS_MAC
static const UInt32 kVibeAudioMicrophoneDisableFlag = 0;
#endif
static const UInt32 kVibeAudioMicrophoneEnableFlag  = 1;
//double externSampleRate;

@interface VibedataInput (){
  BOOL _customASBD;
  BOOL _isConfigured;
  BOOL _isFetching;
  
  AEFloatConverter            *converter;
  AudioStreamBasicDescription streamFormat;
  
  AudioUnit microphoneInput;
  
  float           **floatBuffers;
  AudioBufferList *microphoneInputBuffer;
  
  Float64 _deviceSampleRate;
  Float32 _deviceBufferDuration;
  UInt32  _deviceBufferFrameSize;
  
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
  Float64 inputScopeSampleRate;
#endif
  
}
@end

extern int flagConnected = 0;


@implementation VibedataInput
@synthesize microphoneDelegate = _microphoneDelegate;
@synthesize microphoneOn = _microphoneOn;

#pragma mark - Callbacks
static OSStatus inputCallback(void                          *inRefCon,
                              AudioUnitRenderActionFlags    *ioActionFlags,
                              const AudioTimeStamp          *inTimeStamp,
                              UInt32                        inBusNumber,
                              UInt32                        inNumberFrames,
                              AudioBufferList               *ioData ) {
  VibedataInput *microphone = (__bridge VibedataInput*)inRefCon;
  OSStatus      result     = noErr;
    
    NSString *DeviceName;
    for (AVAudioSessionPortDescription *portDesc in [[[AVAudioSession sharedInstance] currentRoute] inputs ]) {
        DeviceName = [NSString stringWithFormat:@"%@", portDesc.portName];

        if ([DeviceName isEqualToString:@"iPad Microphone"]) {
            flagConnected = 1;
        }
        else if ([DeviceName isEqualToString:@"Wireless Vibration Receiver"]) {
            flagConnected = 1;
        }
        else if ([DeviceName isEqualToString:@"Sonic Port"]) {
            flagConnected = 2;
        }
        else if ([DeviceName isEqualToString:@"Wired Vibration Receiver"]) {
            flagConnected = 2;
        }
        else if ([DeviceName isEqualToString:@"iMic USB audio system"]) {
            flagConnected = 3;
        }
        else if ([DeviceName isEqualToString:@"USB Audio Device"]) {
            flagConnected = 4;
        }
        else {
            flagConnected = 10;
        }
    }
 
    
  result = AudioUnitRender(microphone->microphoneInput,
                           ioActionFlags,
                           inTimeStamp,
                           inBusNumber,
                           inNumberFrames,
                           microphone->microphoneInputBuffer);
  
  if( !result ){
    if( microphone.microphoneDelegate ){
      if( [microphone.microphoneDelegate respondsToSelector:@selector(microphone:hasAudioReceived:withBufferSize:withNumberOfChannels:)] ){
        AEFloatConverterToFloat(microphone->converter,
                                microphone->microphoneInputBuffer,
                                microphone->floatBuffers,
                                inNumberFrames);
        [microphone.microphoneDelegate microphone:microphone
                                 hasAudioReceived:microphone->floatBuffers
                                   withBufferSize:inNumberFrames
                             withNumberOfChannels:microphone->streamFormat.mChannelsPerFrame];
      }
    }
    if( microphone.microphoneDelegate ){
      if( [microphone.microphoneDelegate respondsToSelector:@selector(microphone:hasBufferList:withBufferSize:withNumberOfChannels:)] ){
        [microphone.microphoneDelegate microphone:microphone
                                    hasBufferList:microphone->microphoneInputBuffer
                                   withBufferSize:inNumberFrames
                             withNumberOfChannels:microphone->streamFormat.mChannelsPerFrame];
      }
    }
  }
  return result;
}

#pragma mark - Initialization
-(id)init {
  self = [super init];
  if(self){
    floatBuffers = NULL;
    _isConfigured = NO;
    _isFetching   = NO;
    if( !_isConfigured ){
      [self _createInputUnit];
      _isConfigured = YES;
    }
  }
  return self;
}

-(VibedataInput *)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate {
  self = [super init];
    if(self){
    self.microphoneDelegate = microphoneDelegate;
    floatBuffers = NULL;
    _isConfigured = NO;
    _isFetching   = NO;
    if( !_isConfigured ){
      [self _createInputUnit];
      _isConfigured = YES;
    }
  }
  return self;
}

-(VibedataInput *)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate
            withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
  self = [self initWithMicrophoneDelegate:microphoneDelegate];
  if(self){
    _customASBD  = YES;
    streamFormat = audioStreamBasicDescription;
  }
  return self;
}

-(VibedataInput *)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate
                           startsImmediately:(BOOL)startsImmediately {
  self = [self initWithMicrophoneDelegate:microphoneDelegate];
  if(self){
    startsImmediately ? [self startFetchingAudio] : -1;
  }
  return self;
}

-(VibedataInput *)initWithMicrophoneDelegate:(id<VibedataInputDelegate>)microphoneDelegate
            withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
                          startsImmediately:(BOOL)startsImmediately {
  self = [self initWithMicrophoneDelegate:microphoneDelegate withAudioStreamBasicDescription:audioStreamBasicDescription];
  if(self){
    startsImmediately ? [self startFetchingAudio] : -1;
  }
  return self;
}

#pragma mark - Class Initializers
+(VibedataInput *)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate {
  return [[VibedataInput alloc] initWithMicrophoneDelegate:microphoneDelegate];
}

+(VibedataInput *)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate
        withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
  return [[VibedataInput alloc] initWithMicrophoneDelegate:microphoneDelegate
                          withAudioStreamBasicDescription:audioStreamBasicDescription];
}

+(VibedataInput *)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate
                       startsImmediately:(BOOL)startsImmediately {
  return [[VibedataInput alloc] initWithMicrophoneDelegate:microphoneDelegate
                                         startsImmediately:startsImmediately];
}

+(VibedataInput *)microphoneWithDelegate:(id<VibedataInputDelegate>)microphoneDelegate
        withAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
                      startsImmediately:(BOOL)startsImmediately {
  return [[VibedataInput alloc] initWithMicrophoneDelegate:microphoneDelegate
                          withAudioStreamBasicDescription:audioStreamBasicDescription
                                        startsImmediately:startsImmediately];
}

#pragma mark - Singleton
+(VibedataInput*)sharedMicrophone {
  static VibedataInput *_sharedMicrophone = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedMicrophone = [[VibedataInput alloc] init];
  });
  return _sharedMicrophone;
}

#pragma mark - Events
-(void)startFetchingAudio {
  if( !_isFetching ){
    [VibeAudio checkResult:AudioOutputUnitStart(self->microphoneInput)
               operation:"Microphone failed to start fetching audio"];
    _isFetching = YES;
    self.microphoneOn = YES;
  }
}

-(void)stopFetchingAudio {
  if( _isConfigured ){
    if( _isFetching ){
      [VibeAudio checkResult:AudioOutputUnitStop(self->microphoneInput)
                 operation:"Microphone failed to stop fetching audio"];
      _isFetching = NO;
      self.microphoneOn = NO;
    }
  }
}

#pragma mark - Getters
-(AudioStreamBasicDescription)audioStreamBasicDescription {
  return streamFormat;
}

#pragma mark - Setter
-(void)setMicrophoneOn:(BOOL)microphoneOn {
  _microphoneOn = microphoneOn;
  if( microphoneOn ){
    [self startFetchingAudio];
  }
  else {
    [self stopFetchingAudio];
  }
}

-(void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
  if( self.microphoneOn ){
    NSAssert(self.microphoneOn,@"Cannot set the AudioStreamBasicDescription while microphone is fetching audio");
  }
  else {
    _customASBD = YES;
    streamFormat = asbd;
    [self _configureStreamFormatWithSampleRate:_deviceSampleRate];
  }  
}


-(void) ChangeAUSR {
    kAudioSessionProperty_PreferredHardwareSampleRate:error:
    [self _configureStreamFormatWithSampleRate:VSMainViewController.getExternSampleRate];
//    NSLog(@"AUSR externSampleRate: %f", externSampleRate);
}



#pragma mark - Configure The Input Unit

-(void)_createInputUnit {
  AudioComponentDescription inputComponentDescription = [self _getInputAudioComponentDescription];
  
  AudioComponent inputComponent = [self _getInputComponentWithAudioComponentDescription:inputComponentDescription];
  
  [self _createNewInstanceForInputComponent:inputComponent];
  
  [self _enableInputScope];
  
  [self _disableOutputScope];
  
  #if TARGET_OS_IPHONE
  #elif TARGET_OS_MAC
    [self _configureDefaultDevice];
  #endif
  
    _deviceSampleRate = [self _configureDeviceSampleRateWithDefault:VSMainViewController.getExternSampleRate];
  
    _deviceBufferDuration = [self _configureDeviceBufferDurationWithDefault:0.093];
  
  [self _configureStreamFormatWithSampleRate:_deviceSampleRate];
  
  [self _notifyDelegateOfStreamFormat];
  
    _deviceBufferFrameSize = [self _getBufferFrameSize];
  
  [self _configureAudioBufferListWithFrameSize:_deviceBufferFrameSize];
  
  [self _configureFloatConverterWithFrameSize:_deviceBufferFrameSize];
  
  [self _configureInputCallback];
  
  [self _disableCallbackBufferAllocation];
  
  [VibeAudio checkResult:AudioUnitInitialize( microphoneInput )
             operation:"Couldn't initialize the input unit"];
  
}

#pragma mark - Audio Component Initialization
-(AudioComponentDescription)_getInputAudioComponentDescription {
  AudioComponentDescription inputComponentDescription;
  inputComponentDescription.componentType             = kAudioUnitType_Output;
  inputComponentDescription.componentManufacturer     = kAudioUnitManufacturer_Apple;
  inputComponentDescription.componentFlags            = 0;
  inputComponentDescription.componentFlagsMask        = 0;
  #if TARGET_OS_IPHONE
    inputComponentDescription.componentSubType          = kAudioUnitSubType_RemoteIO;
  #elif TARGET_OS_MAC
    inputComponentDescription.componentSubType          = kAudioUnitSubType_HALOutput;
  #endif
  
  return inputComponentDescription;
  
}

-(AudioComponent)_getInputComponentWithAudioComponentDescription:(AudioComponentDescription)audioComponentDescription {
  
  AudioComponent inputComponent = AudioComponentFindNext( NULL , &audioComponentDescription );
  NSAssert(inputComponent,@"Couldn't get input component unit!");
  return inputComponent;
  
}

-(void)_createNewInstanceForInputComponent:(AudioComponent)audioComponent {
  
  [VibeAudio checkResult:AudioComponentInstanceNew(audioComponent,
                                                 &microphoneInput )
             operation:"Couldn't open component for microphone input unit."];
  
}

#pragma mark - Input/Output Scope Initialization
-(void)_disableOutputScope {
  [VibeAudio checkResult:AudioUnitSetProperty(microphoneInput,
                                            kAudioOutputUnitProperty_EnableIO,
                                            kAudioUnitScope_Output,
                                            kVibeAudioMicrophoneOutputBus,
                                            &kVibeAudioMicrophoneDisableFlag,
                                            sizeof(kVibeAudioMicrophoneDisableFlag))
             operation:"Couldn't disable output on I/O unit."];
}

-(void)_enableInputScope {
  [VibeAudio checkResult:AudioUnitSetProperty(microphoneInput,
                                            kAudioOutputUnitProperty_EnableIO,
                                            kAudioUnitScope_Input,
                                            kVibeAudioMicrophoneInputBus,
                                            &kVibeAudioMicrophoneEnableFlag,
                                            sizeof(kVibeAudioMicrophoneEnableFlag))
             operation:"Couldn't enable input on I/O unit."];
}

#pragma mark - Pull Default Device (OSX)
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
-(void)_configureDefaultDevice {
  AudioDeviceID defaultDevice = kAudioObjectUnknown;
  UInt32 propSize = sizeof(defaultDevice);
  AudioObjectPropertyAddress defaultDeviceProperty;
  defaultDeviceProperty.mSelector                  = kAudioHardwarePropertyDefaultInputDevice;
  defaultDeviceProperty.mScope                     = kAudioObjectPropertyScopeGlobal;
  defaultDeviceProperty.mElement                   = kAudioObjectPropertyElementMaster;
  [VibeAudio checkResult:AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                                  &defaultDeviceProperty,
                                                  0,
                                                  NULL,
                                                  &propSize,
                                                  &defaultDevice)
             operation:"Couldn't get default input device"];
  
  propSize = sizeof(defaultDevice);
  [VibeAudio checkResult:AudioUnitSetProperty(microphoneInput,
                                            kAudioOutputUnitProperty_CurrentDevice,
                                            kAudioUnitScope_Global,
                                            kVibeAudioMicrophoneOutputBus,
                                            &defaultDevice,
                                            propSize)
             operation:"Couldn't set default device on I/O unit"];
  
  AudioStreamBasicDescription inputScopeFormat;
  propSize = sizeof(AudioStreamBasicDescription);
  [VibeAudio checkResult:AudioUnitGetProperty(microphoneInput,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Output,
                                            kVibeAudioMicrophoneInputBus,
                                            &inputScopeFormat,
                                            &propSize)
             operation:"Couldn't get ASBD from input unit (1)"];
  
  AudioStreamBasicDescription outputScopeFormat;
  propSize = sizeof(AudioStreamBasicDescription);
  [VibeAudio checkResult:AudioUnitGetProperty(microphoneInput,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input,
                                            kVibeAudioMicrophoneInputBus,
                                            &outputScopeFormat,
                                            &propSize)
             operation:"Couldn't get ASBD from input unit (2)"];
  
  inputScopeSampleRate = inputScopeFormat.mSampleRate;
  
}
#endif

#pragma mark - Pull Sample Rate
-(Float64)_configureDeviceSampleRateWithDefault:(float)defaultSampleRate {
  Float64 hardwareSampleRate = defaultSampleRate;
  #if TARGET_OS_IPHONE
    #if !(TARGET_IPHONE_SIMULATOR)
    UInt32 propSize = sizeof(Float64);
    [VibeAudio checkResult:AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                                                 &propSize,
                                                 &hardwareSampleRate)
               operation:"Could not get hardware sample rate from device"];
    #endif
  #elif TARGET_OS_MAC
    hardwareSampleRate = inputScopeSampleRate;
  #endif
//    NSLog(@"hardwareSampleRate: %g",hardwareSampleRate);
    return hardwareSampleRate;
}

#pragma mark - Pull Buffer Duration
-(Float32)_configureDeviceBufferDurationWithDefault:(float)defaultBufferDuration {
  Float32 bufferDuration = defaultBufferDuration; // Type 1/43 by default
    
  #if TARGET_OS_IPHONE
    #if !(TARGET_IPHONE_SIMULATOR)
      UInt32 propSize = sizeof(Float32);
      [VibeAudio checkResult:AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,
                                                 propSize,
                                                 &bufferDuration)
               operation:"Couldn't set the preferred buffer duration from device"];
//    NSLog(@"bufferDuration Preferred: %g",bufferDuration);

      propSize = sizeof(bufferDuration);
      [VibeAudio checkResult:AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration,
                                                 &propSize,
                                                 &bufferDuration)
               operation:"Could not get preferred buffer size from device"];
//    NSLog(@"bufferDuration Current Device: %g",bufferDuration);

    #endif
  #elif TARGET_OS_MAC
  
  #endif
    
    return bufferDuration;

}

#pragma mark - Pull Buffer Frame Size
-(UInt32)_getBufferFrameSize {
  UInt32 bufferFrameSize;
  UInt32 propSize = sizeof(bufferFrameSize);
  [VibeAudio checkResult:AudioUnitGetProperty(microphoneInput,
                                            #if TARGET_OS_IPHONE
                                              kAudioUnitProperty_MaximumFramesPerSlice,
                                            #elif TARGET_OS_MAC
                                              kAudioDevicePropertyBufferFrameSize,
                                            #endif
                                            kAudioUnitScope_Global,
                                            kVibeAudioMicrophoneOutputBus,
                                            &bufferFrameSize,
                                            &propSize)
             operation:"Failed to get buffer frame size"];
    bufferFrameSize = 4096;
    return bufferFrameSize;
}


#pragma mark - Stream Format Initialization
-(void)_configureStreamFormatWithSampleRate:(Float64)sampleRate {
    

  if( !_customASBD ){
    streamFormat = [VibeAudio stereoCanonicalNonInterleavedFormatWithSampleRate:sampleRate];
  }
  else {
    streamFormat.mSampleRate = sampleRate;
  }
  UInt32 propSize = sizeof(streamFormat);
  [VibeAudio checkResult:AudioUnitSetProperty(microphoneInput,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input,
                                            kVibeAudioMicrophoneOutputBus,
                                            &streamFormat,
                                            propSize)
             operation:"Could not set microphone's stream format bus 0"];
  
  [VibeAudio checkResult:AudioUnitSetProperty(microphoneInput,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Output,
                                            kVibeAudioMicrophoneInputBus,
                                            &streamFormat,
                                            propSize)
             operation:"Could not set microphone's stream format bus 1"];
}

-(void)_notifyDelegateOfStreamFormat {
  if( _microphoneDelegate ){
    if( [_microphoneDelegate respondsToSelector:@selector(microphone:hasAudioStreamBasicDescription:) ] ){
      [_microphoneDelegate microphone:self
       hasAudioStreamBasicDescription:streamFormat];
    }
  }
}

#pragma mark - AudioBufferList Initialization
-(void)_configureAudioBufferListWithFrameSize:(UInt32)bufferFrameSize {
  UInt32 bufferSizeBytes = bufferFrameSize * streamFormat.mBytesPerFrame;
  UInt32 propSize = offsetof( AudioBufferList, mBuffers[0] ) + ( sizeof( AudioBuffer ) *streamFormat.mChannelsPerFrame );
  microphoneInputBuffer                 = (AudioBufferList*)malloc(propSize);
  microphoneInputBuffer->mNumberBuffers = streamFormat.mChannelsPerFrame;
  for( UInt32 i = 0; i < microphoneInputBuffer->mNumberBuffers; i++ ){
    microphoneInputBuffer->mBuffers[i].mNumberChannels = streamFormat.mChannelsPerFrame;
    microphoneInputBuffer->mBuffers[i].mDataByteSize   = bufferSizeBytes;
    microphoneInputBuffer->mBuffers[i].mData           = malloc(bufferSizeBytes);
  }
}

#pragma mark - Float Converter Initialization
-(void)_configureFloatConverterWithFrameSize:(UInt32)bufferFrameSize {
  UInt32 bufferSizeBytes = bufferFrameSize * streamFormat.mBytesPerFrame;
  converter              = [[AEFloatConverter alloc] initWithSourceFormat:streamFormat];
  floatBuffers           = (float**)malloc(sizeof(float*)*streamFormat.mChannelsPerFrame);
  assert(floatBuffers);
  for ( int i=0; i<streamFormat.mChannelsPerFrame; i++ ) {
    floatBuffers[i] = (float*)malloc(bufferSizeBytes);
    assert(floatBuffers[i]);
  }
}

#pragma mark - Input Callback Initialization
-(void)_configureInputCallback {
  AURenderCallbackStruct microphoneCallbackStruct;
  microphoneCallbackStruct.inputProc       = inputCallback;
  microphoneCallbackStruct.inputProcRefCon = (__bridge void *)self;
  [VibeAudio checkResult:AudioUnitSetProperty(microphoneInput,
                                            kAudioOutputUnitProperty_SetInputCallback,
                                            kAudioUnitScope_Global,
                                            // output bus for mac
                                            #if TARGET_OS_IPHONE
                                              kVibeAudioMicrophoneInputBus,
                                            #elif TARGET_OS_MAC
                                              kVibeAudioMicrophoneOutputBus,
                                            #endif
                                            &microphoneCallbackStruct,
                                            sizeof(microphoneCallbackStruct))
             operation:"Couldn't set input callback"];
}

-(void)_disableCallbackBufferAllocation {
  [VibeAudio checkResult:AudioUnitSetProperty(microphoneInput,
                                            kAudioUnitProperty_ShouldAllocateBuffer,
                                            kAudioUnitScope_Output,
                                            kVibeAudioMicrophoneInputBus,
                                            &kVibeAudioMicrophoneDisableFlag,
                                            sizeof(kVibeAudioMicrophoneDisableFlag))
             operation:"Could not disable audio unit allocating its own buffers"];
}

+ (int)getFlagConnected {
    
    return flagConnected;
}

@end

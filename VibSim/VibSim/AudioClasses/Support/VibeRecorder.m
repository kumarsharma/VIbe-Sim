//
//  VibeRecorder.m
//


#import "VibeRecorder.h"

#import "VibeAudio.h"

@interface VibeRecorder (){
  AudioConverterRef           _audioConverter;
  AudioStreamBasicDescription _clientFormat;
  ExtAudioFileRef             _destinationFile;
  CFURLRef                    _destinationFileURL;
  AudioStreamBasicDescription _destinationFormat;
  AudioStreamBasicDescription _sourceFormat;
}

typedef struct {
  AudioBufferList *sourceBuffer;
} VibeRecorderConverterStruct;

@end

@implementation VibeRecorder

#pragma mark - Initializers
-(VibeRecorder*)initWithDestinationURL:(NSURL*)url
                     andSourceFormat:(AudioStreamBasicDescription)sourceFormat {
  self = [super init];
  if(self){
    _destinationFileURL = (__bridge CFURLRef)url;
    _sourceFormat = sourceFormat;
    _destinationFormat = [VibeRecorder defaultDestinationFormat];
    [self _configureRecorder];
  }
  return self;
}

#pragma mark - Class Initializers
+(VibeRecorder*)recorderWithDestinationURL:(NSURL*)url
                         andSourceFormat:(AudioStreamBasicDescription)sourceFormat {
  return [[VibeRecorder alloc] initWithDestinationURL:url
                                    andSourceFormat:sourceFormat];
}

#pragma mark - Getters
-(NSURL *)url {
  return (__bridge NSURL *)(_destinationFileURL);
}

#pragma mark - Class Format Helper
+(AudioStreamBasicDescription)defaultDestinationFormat {
  AudioStreamBasicDescription destinationFormat = [VibeAudio stereoFloatInterleavedFormatWithSampleRate:44100.0];
  return destinationFormat;
}

+(NSString *)defaultDestinationFormatExtension {
  return @"caf";
}

#pragma mark - Private Configuation
-(void)_configureRecorderForExistingFile {
  
}

-(void)_configureRecorderForNewFile {
  
}

-(void)_configureRecorder {

  [VibeAudio checkResult:ExtAudioFileCreateWithURL(_destinationFileURL,
                                              kAudioFileCAFType,
                                              &_destinationFormat,
                                              NULL,
                                              kAudioFileFlags_EraseFile,
                                              &_destinationFile)
             operation:"Could not open audio file"];

  
  _clientFormat = _destinationFormat;
  if( _destinationFormat.mFormatID != kAudioFormatLinearPCM ){
    [VibeAudio setCanonicalAudioStreamBasicDescription:_destinationFormat
                                    numberOfChannels:_destinationFormat.mChannelsPerFrame
                                         interleaved:YES];
  }
  
  UInt32 propertySize = sizeof(_clientFormat);
  [VibeAudio checkResult:ExtAudioFileSetProperty(_destinationFile,
                                               kExtAudioFileProperty_ClientDataFormat,
                                               propertySize,
                                               &_clientFormat)
             operation:"Failed to set client data format on destination file"];
  
  [VibeAudio checkResult:ExtAudioFileWriteAsync(_destinationFile, 0, NULL)
             operation:"Failed to initialize with ExtAudioFileWriteAsync"];
  
  [VibeAudio checkResult:AudioConverterNew(&_sourceFormat, &_clientFormat, &_audioConverter)
             operation:"Failed to create new audio converter"];
  
}

#pragma mark - Events
-(void)appendDataFromBufferList:(AudioBufferList*)bufferList
                 withBufferSize:(UInt32)bufferSize {
  
  AudioBufferList *convertedData = [VibeAudio audioBufferListWithNumberOfFrames:bufferSize
                                                             numberOfChannels:_clientFormat.mChannelsPerFrame
                                                                  interleaved:!(_clientFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved)];
  
  [VibeAudio checkResult:AudioConverterFillComplexBuffer(_audioConverter,
                                                       complexInputDataProc,
                                                       &(VibeRecorderConverterStruct){ .sourceBuffer = bufferList },
                                                       &bufferSize,
                                                       convertedData,
                                                       NULL)
             operation:"Failed while converting buffers"];
  
  [VibeAudio checkResult:ExtAudioFileWriteAsync(_destinationFile,bufferSize,convertedData)
             operation:"Failed to write audio data to file"];
  
  [VibeAudio freeBufferList:convertedData];
  
}

-(void)closeAudioFile {
  if( _destinationFile ){
    [VibeAudio checkResult:ExtAudioFileDispose(_destinationFile)
               operation:"Failed to close audio file for recorder"];
    _destinationFile = NULL;
  }
}

#pragma mark - Converter Processing
static OSStatus complexInputDataProc(AudioConverterRef             inAudioConverter,
                                     UInt32                        *ioNumberDataPackets,
                                     AudioBufferList               *ioData,
                                     AudioStreamPacketDescription  **outDataPacketDescription,
                                     void                          *inUserData) {
  VibeRecorderConverterStruct *recorderStruct = (VibeRecorderConverterStruct*)inUserData;
  
  if ( !recorderStruct->sourceBuffer ) {
    return -2222; 
  }

  memcpy(ioData,
         recorderStruct->sourceBuffer,
         sizeof(AudioBufferList)+(recorderStruct->sourceBuffer->mNumberBuffers-1)*sizeof(AudioBuffer));
  recorderStruct->sourceBuffer = NULL;
  
  return noErr;
}

#pragma mark - Cleanup
-(void)dealloc {
  if( _audioConverter )
  {
    [VibeAudio checkResult:AudioConverterDispose(_audioConverter)
               operation:"Failed to dispose audio converter in recorder"];
  }
  if( _destinationFile )
  {
    [VibeAudio checkResult:ExtAudioFileDispose(_destinationFile)
               operation:"Failed to dispose extended audio file in recorder"];
  }
}

@end

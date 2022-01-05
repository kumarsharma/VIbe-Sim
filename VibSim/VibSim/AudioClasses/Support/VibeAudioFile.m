//
//  VibeAudioFile.m
//


#import "VibeAudioFile.h"

#import "VibeAudio.h"

#define kVibeAudioFileWaveformDefaultResolution (4096)

@interface VibeAudioFile (){
  
  ExtAudioFileRef             _audioFile;
  AudioStreamBasicDescription _clientFormat;
  AudioStreamBasicDescription _fileFormat;
  float                       **_floatBuffers;
  AEFloatConverter            *_floatConverter;
  SInt64                      _frameIndex;
  CFURLRef                    _sourceURL;
  Float32                     _totalDuration;
  SInt64                      _totalFrames;
  
  float  *_waveformData;
  UInt32 _waveformFrameRate;
  UInt32 _waveformTotalBuffers;
  
}
@end

@implementation VibeAudioFile
@synthesize audioFileDelegate = _audioFileDelegate;
@synthesize waveformResolution = _waveformResolution;

#pragma mark - Initializers
-(VibeAudioFile*)initWithURL:(NSURL*)url {
  self = [super init];
  if(self){
    _sourceURL = (__bridge CFURLRef)url;
    [self _configureAudioFile];
  }
  return self;
}

-(VibeAudioFile *)initWithURL:(NSURL *)url andDelegate:(id<VibeAudioFileDelegate>)delegate {
  self = [self initWithURL:url];
  if(self){
    self.audioFileDelegate = delegate;
  }
  return self;
}

#pragma mark - Class Initializers
+(VibeAudioFile*)audioFileWithURL:(NSURL*)url {
  return [[VibeAudioFile alloc] initWithURL:url];
}

+(VibeAudioFile *)audioFileWithURL:(NSURL *)url andDelegate:(id<VibeAudioFileDelegate>)delegate {
  return [[VibeAudioFile alloc] initWithURL:url andDelegate:delegate];
}

#pragma mark - Class Methods
+(NSArray *)supportedAudioFileTypes {
  return @[ @"aac",
            @"caf",
            @"aif",
            @"aiff",
            @"aifc",
            @"mp3",
            @"mp4",
            @"m4a",
            @"snd",
            @"au",
            @"sd2",
            @"wav" ];
}

#pragma mark - Private Configuation
-(void)_configureAudioFile {
  
  NSAssert(_sourceURL,@"Source URL was not specified correctly.");
  
  [VibeAudio checkResult:ExtAudioFileOpenURL(_sourceURL,&_audioFile)
             operation:"Failed to open audio file for reading"];
  
  UInt32 size = sizeof(_fileFormat);
  [VibeAudio checkResult:ExtAudioFileGetProperty(_audioFile,kExtAudioFileProperty_FileDataFormat, &size, &_fileFormat)
             operation:"Failed to get audio stream basic description of input file"];
  
  size = sizeof(_totalFrames);
  [VibeAudio checkResult:ExtAudioFileGetProperty(_audioFile,kExtAudioFileProperty_FileLengthFrames, &size, &_totalFrames)
             operation:"Failed to get total frames of input file"];
  _totalFrames = MAX(1, _totalFrames);
  
  _totalDuration = _totalFrames / _fileFormat.mSampleRate;
  
  switch (_fileFormat.mChannelsPerFrame) {
    case 1:
      _clientFormat = [VibeAudio monoFloatFormatWithSampleRate:_fileFormat.mSampleRate];
      break;
    case 2:
      _clientFormat = [VibeAudio stereoFloatInterleavedFormatWithSampleRate:_fileFormat.mSampleRate];
      break;
    default:
      break;
  }
    
  [VibeAudio checkResult:ExtAudioFileSetProperty(_audioFile,
                                               kExtAudioFileProperty_ClientDataFormat,
                                               sizeof (AudioStreamBasicDescription),
                                               &_clientFormat)
             operation:"Couldn't set client data format on input ext file"];
  
  _floatConverter = [[AEFloatConverter alloc] initWithSourceFormat:_clientFormat];
  size_t sizeToAllocate = sizeof(float*) * _clientFormat.mChannelsPerFrame;
  sizeToAllocate = MAX(8, sizeToAllocate);
  _floatBuffers   = (float**)malloc( sizeToAllocate );
  UInt32 outputBufferSize = 32 * 1024; // 32 KB
  for ( int i=0; i< _clientFormat.mChannelsPerFrame; i++ ) {
    _floatBuffers[i] = (float*)malloc(outputBufferSize);
  }
  
  _waveformData = NULL;
  
  _waveformResolution = kVibeAudioFileWaveformDefaultResolution;
  
}

#pragma mark - Events
-(void)readFrames:(UInt32)frames
  audioBufferList:(AudioBufferList *)audioBufferList
       bufferSize:(UInt32 *)bufferSize
              eof:(BOOL *)eof {

    [VibeAudio checkResult:ExtAudioFileRead(_audioFile,
                                          &frames,
                                          audioBufferList)
               operation:"Failed to read audio data from audio file"];
    *bufferSize = audioBufferList->mBuffers[0].mDataByteSize/sizeof(AudioUnitSampleType);
    *eof = frames == 0;
    _frameIndex += frames;
    if( self.audioFileDelegate ){
      if( [self.audioFileDelegate respondsToSelector:@selector(audioFile:updatedPosition:)] ){
        [self.audioFileDelegate audioFile:self
                          updatedPosition:_frameIndex];
      }
      if( [self.audioFileDelegate respondsToSelector:@selector(audioFile:readAudio:withBufferSize:withNumberOfChannels:)] ){
        AEFloatConverterToFloat(_floatConverter,audioBufferList,_floatBuffers,frames);
        [self.audioFileDelegate audioFile:self
                                readAudio:_floatBuffers
                           withBufferSize:frames
                     withNumberOfChannels:_clientFormat.mChannelsPerFrame];
      }
    }
//  }
}

-(void)seekToFrame:(SInt64)frame {
  [VibeAudio checkResult:ExtAudioFileSeek(_audioFile,frame)
             operation:"Failed to seek frame position within audio file"];
  _frameIndex = frame;
  if( self.audioFileDelegate ){
    if( [self.audioFileDelegate respondsToSelector:@selector(audioFile:updatedPosition:)] ){
      [self.audioFileDelegate audioFile:self updatedPosition:_frameIndex];
    }
  }
}

#pragma mark - Getters
-(BOOL)hasLoadedAudioData {
  return _waveformData != NULL;
}

-(void)getWaveformDataWithCompletionBlock:(WaveformDataCompletionBlock)waveformDataCompletionBlock {
    
  SInt64 currentFramePosition = _frameIndex;
  
  if( _waveformData != NULL ){
    waveformDataCompletionBlock( _waveformData, _waveformTotalBuffers );
    return;
  }
  
  _waveformFrameRate    = [self recommendedDrawingFrameRate];
  _waveformTotalBuffers = [self minBuffersWithFrameRate:_waveformFrameRate];
  _waveformData         = (float*)malloc(sizeof(float)*_waveformTotalBuffers);
  
  if( self.totalFrames == 0 ){
    waveformDataCompletionBlock( _waveformData, _waveformTotalBuffers );
    return;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0ul), ^{
    
    for( int i = 0; i < _waveformTotalBuffers; i++ ){
      
      AudioBufferList *bufferList = [VibeAudio audioBufferListWithNumberOfFrames:_waveformFrameRate
                                                              numberOfChannels:_clientFormat.mChannelsPerFrame
                                                                   interleaved:YES];
      UInt32 bufferSize;
      BOOL eof;
      
      [VibeAudio checkResult:ExtAudioFileRead(_audioFile,
                                            &_waveformFrameRate,
                                            bufferList)
                 operation:"Failed to read audio data from audio file"];
      bufferSize = bufferList->mBuffers[0].mDataByteSize/sizeof(AudioUnitSampleType);
      bufferSize = MAX(1, bufferSize);
      eof = _waveformFrameRate == 0;
      _frameIndex += _waveformFrameRate;
      
      float rms = [VibeAudio RMS:bufferList->mBuffers[0].mData
                        length:bufferSize];
      _waveformData[i] = rms;
    
      [VibeAudio freeBufferList:bufferList];
      
    }
    
    [VibeAudio checkResult:ExtAudioFileSeek(_audioFile,currentFramePosition)
               operation:"Failed to seek frame position within audio file"];
    _frameIndex = currentFramePosition;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      waveformDataCompletionBlock( _waveformData, _waveformTotalBuffers );
    });

  });
  
}

-(AudioStreamBasicDescription)clientFormat {
  return _clientFormat;
}

-(AudioStreamBasicDescription)fileFormat {
  return _fileFormat;
}

-(SInt64)frameIndex {
  return _frameIndex;
}

-(Float32)totalDuration {
  return _totalDuration;
}

-(SInt64)totalFrames {
  return _totalFrames;
}

-(NSURL *)url {
  return (__bridge NSURL*)_sourceURL;
}

#pragma mark - Setters
-(void)setWaveformResolution:(UInt32)waveformResolution {
  if( _waveformResolution != waveformResolution ){
    _waveformResolution = waveformResolution;
    if( _waveformData ){
      free(_waveformData);
      _waveformData = NULL;
    }
  }
}

#pragma mark - Helpers
-(UInt32)minBuffersWithFrameRate:(UInt32)frameRate {
  frameRate = frameRate > 0 ? frameRate : 1;
  UInt32 val = (UInt32) _totalFrames / frameRate + 1;
  return MAX(1, val);
}

-(UInt32)recommendedDrawingFrameRate {
  UInt32 val = 1;
  if(_waveformResolution > 0){
    val = (UInt32) _totalFrames / _waveformResolution;
    if(val > 1)
      --val;
  }
  return MAX(1, val);
}

#pragma mark - Cleanup
-(void)dealloc {
  if( _waveformData ){
    free(_waveformData);
    _waveformData = NULL;
  }

  _frameIndex = 0;
  _waveformFrameRate = 0;
  _waveformTotalBuffers = 0;
  if( _audioFile ){
    [VibeAudio checkResult:ExtAudioFileDispose(_audioFile)
               operation:"Failed to dispose of audio file"];
  }
}

@end

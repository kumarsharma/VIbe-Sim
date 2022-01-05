//
//  VibeAudioPlayer.m
//


#import "VibeAudioPlayer.h"

#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
#endif
@interface VibeAudioPlayer () <VibeAudioFileDelegate,VibeOutputDataSource> {
  BOOL _eof;
}
@property (nonatomic,strong,setter=setAudioFile:) VibeAudioFile *audioFile;
@property (nonatomic,strong,setter=setOutput:)    VibeOutput    *output;
@end

@implementation VibeAudioPlayer
@synthesize audioFile = _audioFile;
@synthesize audioPlayerDelegate = _audioPlayerDelegate;
@synthesize output = _output;
@synthesize shouldLoop = _shouldLoop;

#pragma mark - Initializers
-(id)init {
  self = [super init];
  if(self){
    [self _configureAudioPlayer];
  }
  return self;
}

-(VibeAudioPlayer*)initWithVibeAudioFile:(VibeAudioFile *)audioFile {
  return [self initWithVibeAudioFile:audioFile withDelegate:nil];
}

-(VibeAudioPlayer *)initWithVibeAudioFile:(VibeAudioFile *)audioFile
                         withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate {
  self = [super init];
  if(self){
    [self _configureAudioPlayer];
    self.audioFile           = audioFile;
    self.audioPlayerDelegate = audioPlayerDelegate;
  }
  return self;
}

-(VibeAudioPlayer *)initWithURL:(NSURL *)url {
  return [self initWithURL:url withDelegate:nil];
}

-(VibeAudioPlayer *)initWithURL:(NSURL *)url
                 withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate {
  self = [super init];
  if(self){
    [self _configureAudioPlayer];
    self.audioFile           = [VibeAudioFile audioFileWithURL:url andDelegate:self];
    self.audioPlayerDelegate = audioPlayerDelegate;
  }
  return self;
}

#pragma mark - Class Initializers
+(VibeAudioPlayer *)audioPlayerWithVibeAudioFile:(VibeAudioFile *)audioFile {
  return [[VibeAudioPlayer alloc] initWithVibeAudioFile:audioFile];
}

+(VibeAudioPlayer *)audioPlayerWithVibeAudioFile:(VibeAudioFile *)audioFile
                                withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate {
  return [[VibeAudioPlayer alloc] initWithVibeAudioFile:audioFile
                                       withDelegate:audioPlayerDelegate];
}

+(VibeAudioPlayer *)audioPlayerWithURL:(NSURL *)url {
  return [[VibeAudioPlayer alloc] initWithURL:url];
}

+(VibeAudioPlayer *)audioPlayerWithURL:(NSURL *)url
                        withDelegate:(id<VibeAudioPlayerDelegate>)audioPlayerDelegate {
  return [[VibeAudioPlayer alloc] initWithURL:url
                               withDelegate:audioPlayerDelegate];
}

#pragma mark - Singleton
+(VibeAudioPlayer *)sharedAudioPlayer {
  static VibeAudioPlayer *_sharedAudioPlayer = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedAudioPlayer = [[VibeAudioPlayer alloc] init];
  });
  return _sharedAudioPlayer;
}

#pragma mark - Private Configuration
-(void)_configureAudioPlayer {
  
  // Defaults
  self.output = [VibeOutput sharedOutput];
  
#if TARGET_OS_IPHONE
  // Configure the AVSession
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  NSError *err = NULL;
  [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
  if( err ){
    NSLog(@"There was an error creating the audio session");
  }
  [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:NULL];
  if( err ){
    NSLog(@"There was an error sending the audio to the speakers");
  }
#elif TARGET_OS_MAC
#endif
  
}

#pragma mark - Getters
-(VibeAudioFile*)audioFile {
  return _audioFile;
}

-(float)currentTime {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  return [VibeAudio MAP:self.audioFile.frameIndex
              leftMin:0
              leftMax:self.audioFile.totalFrames
             rightMin:0
             rightMax:self.audioFile.totalDuration];
}

-(BOOL)endOfFile {
  return _eof;
}

-(SInt64)frameIndex {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  return _audioFile.frameIndex;
}

-(BOOL)isPlaying {
  return self.output.isPlaying;
}

-(VibeOutput*)output {
  NSAssert(_output,@"No output was found, this should by default be the VibeOutput shared instance");
  return _output;
}

-(float)totalDuration {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  return _audioFile.totalDuration;
}

-(SInt64)totalFrames {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  return _audioFile.totalFrames;
}

-(NSURL *)url {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  return _audioFile.url;
}

#pragma mark - Setters
-(void)setAudioFile:(VibeAudioFile *)audioFile {
  if( _audioFile ){
    _audioFile.audioFileDelegate = nil;
  }
  _eof       = NO;
  _audioFile = [VibeAudioFile audioFileWithURL:audioFile.url andDelegate:self];
  NSAssert(_output,@"No output was found, this should by default be the VibeOutput shared instance");
  [_output setAudioStreamBasicDescription:self.audioFile.clientFormat];
}

-(void)setOutput:(VibeOutput*)output {
  _output                  = output;
  _output.outputDataSource = self;
}

#pragma mark - Methods
-(void)play {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  if( _audioFile ){
    [_output startPlayback];
    if( self.frameIndex != self.totalFrames ){
      _eof = NO;
    }
    if( self.audioPlayerDelegate ){
      if( [self.audioPlayerDelegate respondsToSelector:@selector(audioPlayer:didResumePlaybackOnAudioFile:)] ){
        // Notify the delegate we're starting playback
        [self.audioPlayerDelegate audioPlayer:self didResumePlaybackOnAudioFile:_audioFile];
      }
    }
  }
}

-(void)pause {
  NSAssert(self.audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  if( _audioFile ){
    [_output stopPlayback];
    if( self.audioPlayerDelegate ){
      if( [self.audioPlayerDelegate respondsToSelector:@selector(audioPlayer:didPausePlaybackOnAudioFile:)] ){
        [self.audioPlayerDelegate audioPlayer:self didPausePlaybackOnAudioFile:_audioFile];
      }
    }
  }
}

-(void)seekToFrame:(SInt64)frame {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  if( _audioFile ){
    [_audioFile seekToFrame:frame];
  }
  if( self.frameIndex != self.totalFrames ){
    _eof = NO;
  }
}

-(void)stop {
  NSAssert(_audioFile,@"No audio file to perform the seek on, check that VibeAudioFile is not nil");
  if( _audioFile ){
    [_output stopPlayback];
    [_audioFile seekToFrame:0];
    _eof = NO;
  }
}

#pragma mark - VibeAudioFileDelegate
-(void)audioFile:(VibeAudioFile *)audioFile
       readAudio:(float **)buffer
  withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
  if( self.audioPlayerDelegate ){
    if( [self.audioPlayerDelegate respondsToSelector:@selector(audioPlayer:readAudio:withBufferSize:withNumberOfChannels:inAudioFile:)] ){
      [self.audioPlayerDelegate audioPlayer:self
                                  readAudio:buffer
                             withBufferSize:bufferSize
                       withNumberOfChannels:numberOfChannels
                                inAudioFile:audioFile];
    }
  }
}

-(void)audioFile:(VibeAudioFile *)audioFile updatedPosition:(SInt64)framePosition {
  if( self.audioPlayerDelegate ){
    if( [self.audioPlayerDelegate respondsToSelector:@selector(audioPlayer:updatedPosition:inAudioFile:)] ){
      [self.audioPlayerDelegate audioPlayer:self
                            updatedPosition:framePosition
                                inAudioFile:audioFile];
    }
  }
}

#pragma mark - VibeOutputDataSource
-(void)             output:(VibeOutput *)output
 shouldFillAudioBufferList:(AudioBufferList *)audioBufferList
        withNumberOfFrames:(UInt32)frames
{
    if( self.audioFile )
    {
        UInt32 bufferSize;
        [self.audioFile readFrames:frames
                   audioBufferList:audioBufferList
                        bufferSize:&bufferSize
                               eof:&_eof];
        if( _eof && self.shouldLoop )
        {
            [self seekToFrame:0];
        }
    }
}

@end

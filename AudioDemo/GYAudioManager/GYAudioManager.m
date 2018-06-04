//
//  GYAudioManager.m
//  AudioDemo
//
//  Created by qm on 2018/6/4.
//  Copyright © 2018年 qm. All rights reserved.
//

#import "GYAudioManager.h"
#import <lame/lame.h>

#define kGYRecorderRate 44100.0

@interface GYAudioManager ()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) NSURL *originURL;
@property (nonatomic, assign) NSTimeInterval maxDuration;

@end


@implementation GYAudioManager


- (instancetype)initWithRecordURL:(NSURL *)fileURL maxDurarion:(NSTimeInterval)maxDuration
{
    self = [super init];
    if (self) {
        _originURL = fileURL;
        
        if (maxDuration > 0) {
            _maxDuration = maxDuration;
        }
        
#if TARGET_IPHONE_SIMULATOR
        // 模拟器
#else
        // 真机
        [self setAudioSession];
#endif
        
    }
    return self;
}

- (void)startRecord
{
    if (![self.audioRecorder isRecording]) {
        
        if (_maxDuration > 0) {
            [self.audioRecorder recordForDuration:_maxDuration];
        }else
        {
            [self.audioRecorder record];
        }
        
        if (self.audioRecorder) {
            // 创建成功
            self.timer.fireDate = [NSDate distantPast];
        }
        
    }
}


- (void)pause
{
    if (_audioRecorder) {
        
        if ([_audioRecorder isRecording]) {
            [_audioRecorder pause];
            self.timer.fireDate = [NSDate distantFuture];
        }
    }
    
    if (_audioPlayer) {
        if ([_audioPlayer isPlaying]) {
            [_audioPlayer pause];
            self.timer.fireDate = [NSDate distantFuture];
        }
    }
    
}

- (void)stop
{
    
    if (_audioRecorder) {
        [_audioRecorder stop];
    }
    if (_audioPlayer) {
        [_audioPlayer stop];
    }

    
//    self.timer.fireDate = [NSDate distantFuture];
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
}


- (void)playAudioFile:(NSURL *)fileURL
{
    if (_audioPlayer) {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:&error];
    _audioPlayer.numberOfLoops = -1;
    _audioPlayer.delegate = self;
    [_audioPlayer prepareToPlay];
    if (error) {
        NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    [_audioPlayer play];
    self.timer.fireDate = [NSDate distantPast];
    
}

- (void)startConvertToMP3
{
    NSString *souceFilePath = self.originURL.path;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    path = [path stringByAppendingPathComponent:@"AudioPath"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]) {
        // 如果不存在,则说明是第一次运行这个程序，那么建立这个文件夹
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *mp3FilePath = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mp3"];
    
    if ([self.delegate respondsToSelector:@selector(audioManagerDidStartConvertToMP3)]) {
        [self.delegate audioManagerDidStartConvertToMP3];
    }
    
    // 转换格式
    [self conventToMp3WithCafFilePath:souceFilePath mp3FilePath:mp3FilePath sampleRate:kGYRecorderRate callback:^(BOOL result) {
        
        NSURL *mp3URL = nil;
        
        if (result) {
            mp3URL = [NSURL fileURLWithPath:mp3FilePath];
            // 删除录音文件
            [self.audioRecorder deleteRecording];
        }
        
        
        
        //从主线程回调转换完成
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(audioManager:didFinishConvertToMP3:)]) {
                
                [self.delegate audioManager:self didFinishConvertToMP3:mp3URL];
            }
        });
    }];
}

#pragma mark- <AVAudioRecorderDelegate>
// 录音完毕的回调
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    [recorder stop];
    
    // 转换MP3
    if (_autoConvertToMp3) {
        [self startConvertToMP3];
    }
    
    if ([self.delegate respondsToSelector:@selector(audioManager:recorderDidFinishSuccessfully:)]) {
        [self.delegate audioManager:self recorderDidFinishSuccessfully:flag];
    }
}
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error
{
    [recorder stop];
    if ([self.delegate respondsToSelector:@selector(audioManager:recorderEncodeErrorDidOccur:)]) {
        [self.delegate audioManager:self recorderEncodeErrorDidOccur:error];
    }
}


#pragma mark- AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [player stop];
    
    if ([self.delegate respondsToSelector:@selector(audioManager:playerDidFinishPlayingSuccessfully:)]) {
        [self.delegate audioManager:self playerDidFinishPlayingSuccessfully:flag];
    }
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    [player stop];
    if ([self.delegate respondsToSelector:@selector(audioManager:playerDecodeErrorDidOccur:)]) {
        [self.delegate audioManager:self playerDecodeErrorDidOccur:error];
    }
}


#pragma mark- 私有方法

- (void)handleTimerAction
{
    if ([_audioRecorder isRecording]) {
        if ([self.delegate respondsToSelector:@selector(audioManager:didRecordFileDuration:totalDuration:)]) {
            [self.delegate audioManager:self didRecordFileDuration:_audioRecorder.currentTime totalDuration:_maxDuration];
        }
    }
    
    
    
    if (_audioPlayer.isPlaying) {
        if ([self.delegate respondsToSelector:@selector(audioManager:didPlayFileDuration:totalDuration:)]) {
            [self.delegate audioManager:self didPlayFileDuration:_audioPlayer.currentTime totalDuration:_audioPlayer.duration];
        }
    }
    
}

#pragma mark- 转换MP3
- (void)conventToMp3WithCafFilePath:(NSString *)cafFilePath
                        mp3FilePath:(NSString *)mp3FilePath
                         sampleRate:(int)sampleRate
                           callback:(void(^)(BOOL result))callback
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @try {
            int read, write;
            
            FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
            fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
            FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb+");  //output 输出生成的Mp3文件位置
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();
            lame_set_num_channels(lame,1);//设置1为单通道，默认为2双通道
            lame_set_in_samplerate(lame, sampleRate);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            do {
                
                read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
                if (read == 0) {
                    write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                    
                } else {
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }
                
                fwrite(mp3_buffer, write, 1, mp3);
                
            } while (read != 0);
            
            lame_mp3_tags_fid(lame, mp3);
            
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
            if (callback) {
                callback(NO);
            }
        }
        @finally {
            NSLog(@"-----\n  MP3生成成功: %@   -----  \n", mp3FilePath);
            if (callback) {
                callback(YES);
            }
        }
    });
}


/**
 *  设置音频会话
 */
- (void)setAudioSession
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

- (AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder) {
        // 创建录音格式设置
        NSDictionary *setting = [self getAudioSetting];
        // 创建录音机
        NSError *error = nil;
        _audioRecorder = [[AVAudioRecorder alloc]initWithURL:_originURL settings:setting error:&error];
        _audioRecorder.delegate = self;
//        _audioRecorder.meteringEnabled = YES;// 如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}


- (NSDictionary *)getAudioSetting
{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    // 设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    // 设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(kGYRecorderRate) forKey:AVSampleRateKey];
    // 设置通道,这里采用单声道
    [dicM setObject:@(2) forKey:AVNumberOfChannelsKey];
    // 每个采样点位数,分为8、16、24、32
//    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    // 是否使用浮点数采样，转mp3不能设置该值
//    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    
    [dicM setObject:@(AVAudioQualityMedium) forKey:AVEncoderAudioQualityKey];
    
    return dicM;
}

- (NSTimer *)timer
{
    if (nil == _timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handleTimerAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}



@end

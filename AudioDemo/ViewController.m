//
//  ViewController.m
//  AudioDemo
//
//  Created by qm on 2018/6/4.
//  Copyright © 2018年 qm. All rights reserved.
//

#import "ViewController.h"
#import "GYAudioManager.h"

@interface ViewController ()<GYAudioManagerDelegate>

@property (nonatomic, strong) GYAudioManager *audioMgr;

@property (nonatomic, strong) NSURL *originURL;
@property (nonatomic, strong) NSURL *mp3URL;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _originURL = [self getFileURL];
    _audioMgr = [[GYAudioManager alloc] initWithRecordURL:_originURL maxDurarion:10];
    _audioMgr.delegate = self;
    
    
    
}

- (NSURL *)getFileURL
{
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
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".caf"];
    
    NSURL *fileURL = [NSURL fileURLWithPath:fileName];
    
    NSLog(@"file :  %@", fileURL.path);
    
    return fileURL;
}


#pragma mark- GYAudioManagerDelegate
- (void)audioManagerDidStartConvertToMP3
{
    NSLog(@"开始转mp3");
}
- (void)audioManager:(GYAudioManager *)audioMgr didFinishConvertToMP3:(NSURL *)mp3FileURL
{
    _mp3URL = mp3FileURL;
    NSLog(@"转mp3完成  %@", mp3FileURL.path);
}

// 每0.1秒回调
- (void)audioManager:(GYAudioManager *)audioMgr didRecordFileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration
{
    NSLog(@"录制 %.0f : %.0f", fileDuration, totalDuration);
    
}
- (void)audioManager:(GYAudioManager *)audioMgr didPlayFileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration
{
    NSLog(@"播放 %.0f : %.0f", fileDuration, totalDuration);
}





#pragma mark- IBActions
- (IBAction)recordAction {
    [_audioMgr startRecord];
}

- (IBAction)pauseAction:(id)sender {
    [_audioMgr pause];
}

- (IBAction)stopAction:(id)sender {
    [_audioMgr stop];
}

- (IBAction)playActionCaf:(id)sender {
    [_audioMgr playAudioFile:_originURL];
}



- (IBAction)convertMP3:(id)sender {
    [_audioMgr startConvertToMP3];
}

- (IBAction)playActiomp3:(id)sender {
    [_audioMgr playAudioFile:_mp3URL];
}

@end

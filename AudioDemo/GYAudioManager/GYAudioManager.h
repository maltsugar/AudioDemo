//
//  GYAudioManager.h
//  AudioDemo
//
//  Created by qm on 2018/6/4.
//  Copyright © 2018年 qm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class GYAudioManager;
@protocol GYAudioManagerDelegate <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

- (void)audioManagerDidStartConvertToMP3;
- (void)audioManager:(GYAudioManager *)audioMgr didFinishConvertToMP3:(NSURL *)mp3FileURL;

// 每0.1秒回调
- (void)audioManager:(GYAudioManager *)audioMgr didRecordFileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration;
- (void)audioManager:(GYAudioManager *)audioMgr didPlayFileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration;

@end

@interface GYAudioManager : NSObject



@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL autoConvertToMp3;
@property (nonatomic, assign) id<GYAudioManagerDelegate> delegate;


// 录制
// maxDuration <= 0,则为不限制时长
- (instancetype)initWithRecordURL:(NSURL *)fileURL maxDurarion:(CGFloat)maxDuration;
- (void)startRecord;
- (void)startConvertToMP3;


// 播放
- (void)playAudioFile:(NSURL *)fileURL;


// 公共方法（播放录制都可以调用）
- (void)pause;
- (void)stop;

@end

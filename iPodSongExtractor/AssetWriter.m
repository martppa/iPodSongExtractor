//
//  AssetWriter.m
//  iPodSongExtractor
//
//  Created by Humberto Martin on 7/9/17.
//  Copyright © 2017 MartppaSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AssetWriter.h"

@implementation AssetWriter : NSObject

- (id) initWithDestinationURL: (NSURL*) url atTime: (CMTime) startTime {
    
    NSError* error = nil;
    
    assetWriter =
    [AVAssetWriter assetWriterWithURL: url
                             fileType:AVFileTypeCoreAudioFormat
                                error: &error];
    if (error)
    {
        NSString* reason = [[NSString alloc] initWithFormat: @"Error loading buffer writer: %@", [error localizedDescription]];
        NSLog(@"%@", reason);
        @throw [[NSException alloc] initWithName:@"WriterErrorException"
                                          reason:reason
                                        userInfo:nil];
    }
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    //Declaring audio format dictionary
    NSDictionary *outputSettings =
    @{AVFormatIDKey: @(kAudioFormatLinearPCM),
      AVSampleRateKey: @44100.0F,
      AVNumberOfChannelsKey: @2,
      AVChannelLayoutKey:
          [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],
      AVLinearPCMBitDepthKey: @16,
      AVLinearPCMIsNonInterleaved: @NO,
      AVLinearPCMIsFloatKey: @NO,
      AVLinearPCMIsBigEndianKey: @NO};
    //Writer input initialization
    assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                          outputSettings:outputSettings];
    //Adding input de writer
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    } else {
        NSString* reason = [[NSString alloc] initWithFormat:@"Can't add input to writer: %@", [error localizedDescription]];
        NSLog(@"%@", reason);
        @throw [[NSException alloc] initWithName:@"WriterInputErrorException"
                                          reason:reason
                                        userInfo:nil];
    }
    
    assetWriterInput.expectsMediaDataInRealTime = NO;
    
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime: startTime];
    
    mUrl = url;
    
    return self;
}

- (void) startWritingWithReaderOutput: (AVAssetReaderOutput*) output framesPerFile: (uint) frames callback: (void (^)(NSURL* url)) callback {
    
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    remaingsData = true;
    
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:
     ^{
         @synchronized (output) {
             while (assetWriterInput.readyForMoreMediaData) {
                 if (frames > 0)
                     if (convertedByteCount >= frames)
                         break;
                 CMSampleBufferRef nextBuffer;
                 nextBuffer = [output copyNextSampleBuffer];
                 if (nextBuffer) {
                     [assetWriterInput appendSampleBuffer: nextBuffer];
                     convertedByteCount++;
                 } else {
                     remaingsData = false;
                     break;
                 }
                 CMSampleBufferInvalidate(nextBuffer);
                 CFRelease(nextBuffer);
                 nextBuffer = nil;
             }
             
             [assetWriterInput markAsFinished];
             [assetWriter finishWritingWithCompletionHandler: ^{
                 NSLog(@"Buffer finished writing");
             }];
             
             if (callback) {
                 callback(mUrl);
             }
         }
     }];
}

- (void) dealloc {
    mUrl = nil;
    assetWriterInput = nil;
    assetWriter = nil;
}

- (bool) remainsData
{
    return remaingsData;
}

@end

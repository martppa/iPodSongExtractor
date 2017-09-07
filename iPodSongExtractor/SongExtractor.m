//
//  iPodSongExtractor.m
//  iPodSongExtractor
//
//  Created by Humberto Martin on 7/9/17.
//  Copyright © 2017 MartppaSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SongExtractor.h"

@implementation SongExtractor

- (void) extractSongFrom: (NSURL*) url destinationURL: (NSURL*) destinationDirectory removingDirectory: (Boolean) remove framesPerFile: (uint) frames callback: (void (^)(NSURL *bufferUrl)) callback error: (NSError **) error {
    
    writers = [[NSMutableArray alloc] init];
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    NSError* assetError = nil;
    assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&assetError];
    if (assetError) {
        NSLog (@"error: %@", assetError);
        *error = assetError;
        return;
    }
    
    assetReaderOutput = [AVAssetReaderAudioMixOutput
                         assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                         audioSettings: nil];
    
    if (![assetReader canAddOutput: assetReaderOutput]) {
        NSString* reason = @"Can't add reader output";
        NSLog(@"%@", reason);
        *error = [[NSError alloc] initWithDomain:reason code:0 userInfo:nil];
        return;
    }
    
    [assetReader addOutput: assetReaderOutput];
    
    NSArray *dirs = NSSearchPathForDirectoriesInDomains
				(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    NSString *exportPath = [documentsDirectoryPath
                            stringByAppendingPathComponent:EXPORT_NAME];
    
    if (remove)
        [[NSFileManager defaultManager] removeItemAtURL: destinationDirectory error:&assetError];
        if (assetError) {
            NSString* reason = @"Previous buffer wasn't able to be cleared, maybe it never existed.";
            NSLog(@"%@", reason);
        }
    
    [[NSFileManager defaultManager] createDirectoryAtURL: destinationDirectory withIntermediateDirectories: true attributes:nil error:&assetError];
    if (assetError) {
        NSString* reason = [[NSString alloc] initWithFormat:@"Unable to reserve space for new buffers: %@", [assetError  localizedDescription]];
        NSLog(@"%@", reason);
        *error = [[NSError alloc] initWithDomain:reason code:0 userInfo:nil];
        return;
    }
    
    [assetReader startReading];
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    
    __block bool _continue = true;
    __block int bufferCounter = 0;
    
    void (^ __block func)(NSURL* url) = ^(NSURL* url){
        @synchronized (writers) {
            bufferCounter++;
            if ([writers count] > 0)
            {
                _continue = [[writers lastObject] remainsData];
            }
            
            if (_continue) {
                NSString *auxExportPath = [exportPath stringByAppendingString:[NSString stringWithFormat:@"%d", bufferCounter]];
                NSURL *exportURL = [NSURL fileURLWithPath:auxExportPath];
                AssetWriter* newWriter = nil;
                @try {
                    newWriter = [[AssetWriter alloc] initWithDestinationURL: exportURL atTime: startTime];
                } @catch (NSException *exception) {
                    NSString* text = [exception description];
                    NSLog(@"%@", text);
                    *error = [[NSError alloc] initWithDomain:text code:0 userInfo:nil];
                    return;
                }
                [writers addObject:newWriter];
                [newWriter startWritingWithReaderOutput:assetReaderOutput framesPerFile:frames callback:func];
            } else {
                [assetReader cancelReading];
                [writers removeAllObjects];
                assetReader = nil;
                assetReaderOutput = nil;
            }
            
            callback(url);
        }
    };
    
    exportPath = [exportPath stringByAppendingString:[NSString stringWithFormat:@"%d", bufferCounter]];
    NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
    AssetWriter* newWriter = nil;
    @try {
        newWriter = [[AssetWriter alloc] initWithDestinationURL: exportURL atTime: startTime];
    } @catch (NSException* exception) {
        NSString* text = [exception description];
        NSLog(@"%@", text);
        *error = [[NSError alloc] initWithDomain:text code:0 userInfo:nil];
        return;
    }
    
    [writers addObject:newWriter];
    [newWriter startWritingWithReaderOutput:assetReaderOutput framesPerFile:frames callback:func];
}

- (void) dealloc {
    printf("Handler deallocated");
}


@end

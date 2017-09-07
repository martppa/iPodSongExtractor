//
//  SongExtractor.h
//  iPodSongExtractor
//
//  Created by Humberto Martin on 7/9/17.
//  Copyright © 2017 MartppaSoft. All rights reserved.
//
//  
//

#ifndef SongExtractor_h
#define SongExtractor_h

#define EXPORT_NAME @"exported.caf"

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AssetWriter.h"

@interface SongExtractor: NSObject {
    NSMutableArray *writers;
    AVAssetReaderOutput* assetReaderOutput;
    AVAssetReader* assetReader;
}

- (void) extractSongFrom: (NSURL*) url destinationURL: (NSURL*) destinationDirectory removingDirectory: (Boolean) remove framesPerFile: (uint) frames callback: (void (^)(NSURL* bufferUrl)) callback error: (NSError **) error;
@end


#endif /* SongExtractor_h */

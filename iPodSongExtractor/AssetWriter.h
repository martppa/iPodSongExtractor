//
//  AssetWriter.h
//  iPodSongExtractor
//
//  Created by Humberto Martin on 7/9/17.
//  Copyright © 2017 MartppaSoft. All rights reserved.
//

#ifndef AssetWriter_h
#define AssetWriter_h

#define DEFAULT_NUMBER_OF_FRAMES_PER_BUFFER 100

#import <AVFoundation/AVFoundation.h>

@interface AssetWriter : NSObject {
    //Stream writer
    AVAssetWriter* assetWriter;
    AVAssetWriterInput* assetWriterInput;
    NSURL* mUrl;
    bool remaingsData;
}

- (id) initWithDestinationURL: (NSURL*) url atTime: (CMTime) startTime;
- (void) startWritingWithReaderOutput: (AVAssetReaderOutput*) output framesPerFile: (uint) frames callback: (void (^)(NSURL* url)) callback;
- (bool) remainsData;

@end


#endif /* AssetWriter_h */

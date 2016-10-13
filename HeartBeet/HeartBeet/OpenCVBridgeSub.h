//
//  OpenCVBridgeSub.h
//  ImageLab
//
//  Created by Eric Larson on 10/4/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "OpenCVBridge.hh"
#import "CircularBuffer.h"

@interface OpenCVBridgeSub : OpenCVBridge
-(CircularBuffer*) getRedBuffer;
-(float*) getRed;
@end

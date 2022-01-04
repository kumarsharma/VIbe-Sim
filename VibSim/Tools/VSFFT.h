//
//  numpy-style-fft-in-obj-c.h
//
//  Created by John Seales on 12/16/13.
//

#import <Foundation/Foundation.h>
#include <complex.h>
#include <Accelerate/Accelerate.h>

@interface VSFFT : NSObject

+ (DSPDoubleSplitComplex) fft: (float*)input
                   logFFTsize: (NSInteger)logFFTsize;

@end

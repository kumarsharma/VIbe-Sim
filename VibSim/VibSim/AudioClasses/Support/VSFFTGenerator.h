//
//  VSFFTGenerator.h
//  VibSim
//
//  Created by Kumar Sharma on 06/01/22.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

@interface VSFFTGenerator : NSObject

+ (void)toFFT_From_DFTr:(float *)dftR andDFTi:(float *)dftI inFFT1:(float *)fft1 andFFT2:(float *)fft2 forChannel:(int)channel spectrumSize:(NSInteger)specSize  integrationVar:(int)integrationVar amplitudeUnits:(int)amplitudeUnits velocityFactor:(float)velocityFactor Resolution:(double)Resolution displacementFactor:(float)displacementFactor cutOffDisplacement:(int)cutOffDisplacement velRmsPeakInd:(double)velRmsPeakInd flagWindowing:(int)flagWindowing;

@end

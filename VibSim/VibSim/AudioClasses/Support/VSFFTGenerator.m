//
//  VSFFTGenerator.m
//  VibSim
//
//  Created by Kumar Sharma on 06/01/22.
//

#import "VSFFTGenerator.h"

@implementation VSFFTGenerator

vDSP_DFT_Setup m_dftSetup;
vDSP_DFT_Setup m_dftSetup2;

- (id)init {
    
    if ( !(self = [super init]) ) return nil;
    
    return self;
}

+ (void)toFFT_From_DFTr:(float *)dftR andDFTi:(float *)dftI inFFT1:(float *)fft1 andFFT2:(float *)fft2 forChannel:(int)channel spectrumSize:(NSInteger)specSize  integrationVar:(int)integrationVar amplitudeUnits:(int)amplitudeUnits velocityFactor:(float)velocityFactor Resolution:(double)Resolution displacementFactor:(float)displacementFactor cutOffDisplacement:(int)cutOffDisplacement velRmsPeakInd:(double)velRmsPeakInd flagWindowing:(int)flagWindowing
{
    
    float *m_dftR = (float *)malloc(specSize / 2 * sizeof(float));
    float *m_dftI = (float *)malloc(specSize / 2 * sizeof(float));
    float *m_dftR2 = (float *)malloc(specSize / 2 * sizeof(float));
    float *m_dftI2 = (float *)malloc(specSize / 2 * sizeof(float));
    float *m_spectrum = (float *)malloc(specSize / 2 * sizeof(float));
    memset(m_spectrum, 0, specSize / 2 * sizeof(float));
    float *m_spectrum2 = (float *)malloc(specSize / 2 * sizeof(float));
    
    m_dftSetup = vDSP_DFT_zrop_CreateSetup(NULL, specSize, kFFTDirection_Forward);
    m_dftSetup2 = vDSP_DFT_zrop_CreateSetup(NULL, specSize, kFFTDirection_Forward);
    
    if (channel == 0 || channel == 2) {
        for (int i = 0, j = 0; i < specSize / 2; i++, j +=2) {
            m_dftR[i] = 0.0f;
            m_dftI[i] = 0.0f;
            m_dftR[i] += dftR[j];
            m_dftI[i] += dftI[j + 1];
        }
        vDSP_DFT_Execute(m_dftSetup, m_dftR, m_dftI, m_dftR, m_dftI);
        m_spectrum = [self spectrumCalcs: m_dftR with: m_dftI spect: m_spectrum spectrumSize:specSize integrationVar:integrationVar amplitudeUnits:amplitudeUnits velocityFactor:velocityFactor Resolution:Resolution displacementFactor:displacementFactor cutOffDisplacement:cutOffDisplacement velRmsPeakInd:velRmsPeakInd flagWindowing:flagWindowing];
        
    }
    if (channel == 1 || channel == 2) {
        for (int i = 0, j = 0; i < specSize / 2; i++, j +=2) {
            m_dftR2[i] = 0.0f;
            m_dftI2[i] = 0.0f;
            m_dftR2[i] += dftR[j];
            m_dftI2[i] += dftI[j + 1];
        }
        vDSP_DFT_Execute(m_dftSetup2, m_dftR2, m_dftI2, m_dftR2, m_dftI2);
        m_spectrum2 = [self spectrumCalcs: m_dftR2 with: m_dftI2 spect: m_spectrum2 spectrumSize:specSize integrationVar:integrationVar amplitudeUnits:amplitudeUnits velocityFactor:velocityFactor Resolution:Resolution displacementFactor:displacementFactor cutOffDisplacement:cutOffDisplacement velRmsPeakInd:velRmsPeakInd flagWindowing:flagWindowing];
    }
    
    fft1 = m_spectrum;
    fft2 = m_spectrum2;
}

+ (float*)spectrumCalcs: (float*)m_dftR with: (float*)m_dftI spect: (float*) m_spectrum  spectrumSize:(NSInteger)m_spectrumSize integrationVar:(int)integrationVar amplitudeUnits:(int)amplitudeUnits velocityFactor:(float)velocityFactor Resolution:(double)Resolution displacementFactor:(float)displacementFactor cutOffDisplacement:(int)cutOffDisplacement velRmsPeakInd:(double)velRmsPeakInd flagWindowing:(int)flagWindowing
{
    float *m_spectrumTempAcc;
    float *m_spectrumTempVel;
    float *m_spectrumTempDisp;
    m_spectrumTempVel = (float *)malloc(m_spectrumSize / 2 * sizeof(float));
    m_spectrumTempAcc = (float *)malloc(m_spectrumSize / 2 * sizeof(float));
    
    for (int i = 2; i < m_spectrumSize / 2; ++i) {
        if (integrationVar == 0) {
            m_spectrum[i] = hypotf(m_dftR[i] / (float)m_spectrumSize, m_dftI[i] / (float)m_spectrumSize)*0.707;
            m_spectrumTempAcc[i] = hypotf(m_dftR[i] / (float)m_spectrumSize, m_dftI[i] / (float)m_spectrumSize)*0.707;
            if (amplitudeUnits == 0) {
                m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor/(Resolution*i);
            }
            if (amplitudeUnits == 1) {
                m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor*25.4/(Resolution*i);
            }
        }
        if (integrationVar == 1) {
            m_spectrumTempAcc[i] = hypotf(m_dftR[i] / (float)m_spectrumSize, m_dftI[i] / (float)m_spectrumSize)*0.707;
            if (amplitudeUnits == 0) {
                if (velRmsPeakInd == 0) {
                    m_spectrum[i] = m_spectrumTempAcc[i]*velocityFactor/(Resolution*i);
                    m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor/(Resolution*i);
                }
                if (velRmsPeakInd == 1) {
                    m_spectrum[i] = m_spectrumTempAcc[i]*velocityFactor*1.4142/(Resolution*i);
                    m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor*1.4142/(Resolution*i);
                }
            }
            if (amplitudeUnits == 1) {
                if (velRmsPeakInd == 0) {
                    m_spectrum[i] = m_spectrumTempAcc[i]*velocityFactor*25.4/(Resolution*i);
                    m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor*25.4/(Resolution*i);
                }
                if (velRmsPeakInd == 1) {
                    m_spectrum[i] = m_spectrumTempAcc[i]*25.4*1.4142/(Resolution*i);
                    m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor*25.4*1.4142/(Resolution*i);
                }
            }
        }
        if (integrationVar == 2) {
            m_spectrumTempAcc[i] = hypotf(m_dftR[i] / (float)m_spectrumSize, m_dftI[i] / (float)m_spectrumSize)*0.707;
            if (amplitudeUnits == 0) {
                m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor/(Resolution*i);
                m_spectrum[i] = m_spectrumTempAcc[i]*velocityFactor*displacementFactor*1.4142/(Resolution*Resolution*i*i);
                m_spectrumTempDisp[i] = m_spectrumTempAcc[i]*velocityFactor*displacementFactor*1.4142/(Resolution*Resolution*i*i);
            }
            if (amplitudeUnits == 1) {
                m_spectrumTempVel[i] = m_spectrumTempAcc[i]*velocityFactor*25.4/(Resolution*i);
                m_spectrum[i] = m_spectrumTempAcc[i]*velocityFactor*displacementFactor*25.4*1.4142/(Resolution*Resolution*i*i);
                m_spectrumTempDisp[i] = m_spectrumTempAcc[i]*velocityFactor*displacementFactor*25.4*1.4142/(Resolution*Resolution*i*i);
            }
            for (int i = 0; i < (cutOffDisplacement/(Resolution*60)); ++i) {
                m_spectrum[i] = 0;
            }
        }
//        [self processHigherPeak];

        if (flagWindowing == 1) {
            // Hanning Window
            m_spectrum[i] = 0.5 * (1 - cos((2 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1))) * m_spectrum[i];
        }
        if (flagWindowing == 2) {
            // Hamming Window
            m_spectrum[i] = (0.53836 - (0.46164 * cos((2 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1)))) * m_spectrum[i];
        }
        if (flagWindowing == 3) {
            // Blackman Window
            m_spectrum[i] = (0.42659 - (0.49656 * cos((2 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1))) + (0.076849 * cos((4 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1)))) * m_spectrum[i];
        }
        if (flagWindowing == 4) {
            // Flat-Top Window
            m_spectrum[i] = (0.21557895 - (0.41663158 * cos((2 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1))) + (0.277263158 * cos((4 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1))) - (0.083578947 * cos((6 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1))) + (0.006947368 * cos((8 * M_PI * (i + m_spectrumSize/2)) / (m_spectrumSize - 1)))) * m_spectrum[i];
        }
    }
    return m_spectrum;
}
@end

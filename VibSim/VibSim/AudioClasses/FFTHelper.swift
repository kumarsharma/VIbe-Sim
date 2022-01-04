//
//  FFTHelper.swift
//  VibSim
//
//  Created by KS on 24/12/21.
//

import Foundation
import Accelerate

class FFTHelper {
    
    private var mSpectrumAnalysis: FFTSetup?
    private var mDspSplitComplex: DSPSplitComplex
    private var mFFTNormFactor: Float32
    private var mFFTLength: vDSP_Length
    private var mLog2N: vDSP_Length
    
    
    private final var kAdjust0DB: Float32 = 1.5849e-13
    
    
    init(maxFramesPerSlice inMaxFramesPerSlice: Int) {
        mSpectrumAnalysis = nil
        mFFTNormFactor = 1.0/Float32(2*inMaxFramesPerSlice)
        mFFTLength = vDSP_Length(inMaxFramesPerSlice)/2
        mLog2N = vDSP_Length(log2Ceil(UInt32(inMaxFramesPerSlice)))
        mDspSplitComplex = DSPSplitComplex(
            realp: UnsafeMutablePointer.allocate(capacity: Int(mFFTLength)),
            imagp: UnsafeMutablePointer.allocate(capacity: Int(mFFTLength))
        )
        mSpectrumAnalysis = vDSP_create_fftsetup(mLog2N, FFTRadix(kFFTRadix2))
    }
    
    
    deinit {
        vDSP_destroy_fftsetup(mSpectrumAnalysis)
        mDspSplitComplex.realp.deallocate()
        mDspSplitComplex.imagp.deallocate()
    }
    
    
    func computeFFT(_ inAudioData: UnsafePointer<Float32>?, outFFTData: UnsafeMutablePointer<Float32>?) {
        guard
            let inAudioData = inAudioData,
            let outFFTData = outFFTData
        else { return }
        
        //Generate a split complex vector from the real data
        inAudioData.withMemoryRebound(to: DSPComplex.self, capacity: Int(mFFTLength)) {inAudioDataPtr in
            vDSP_ctoz(inAudioDataPtr, 2, &mDspSplitComplex, 1, mFFTLength)
        }
        
        //Take the fft and scale appropriately
        vDSP_fft_zrip(mSpectrumAnalysis!, &mDspSplitComplex, 1, mLog2N, FFTDirection(kFFTDirection_Forward))
        vDSP_vsmul(mDspSplitComplex.realp, 1, &mFFTNormFactor, mDspSplitComplex.realp, 1, mFFTLength)
        vDSP_vsmul(mDspSplitComplex.imagp, 1, &mFFTNormFactor, mDspSplitComplex.imagp, 1, mFFTLength)
        
        //Zero out the nyquist value
        mDspSplitComplex.imagp[0] = 0.0
        
        //Convert the fft data to dB
        vDSP_zvmags(&mDspSplitComplex, 1, outFFTData, 1, mFFTLength)
        
        //In order to avoid taking log10 of zero, an adjusting factor is added in to make the minimum value equal -128dB
        vDSP_vsadd(outFFTData, 1, &kAdjust0DB, outFFTData, 1, mFFTLength)
        var one: Float32 = 1
        vDSP_vdbcon(outFFTData, 1, &one, outFFTData, 1, mFFTLength, 0)
    }
    
    func getFFT(input: [Float32]) -> ([Float], [Float]) {
        
        var real = input
        var imag = [Float](repeating: 0.0, count: input.count)
        var splitComplexBuffer = DSPSplitComplex(realp: &real, imagp: &imag)
        let length = input.count
        let log2n = log2(Float(length))
        let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2n), FFTRadix(kFFTRadix2))!
        
        let halfLength = (input.count/2) + 1
        real = [Float](repeating: 0.0, count: halfLength)
        imag = [Float](repeating: 0.0, count: halfLength)

        // input is alternated across the real and imaginary arrays of the DSPSplitComplex structure
        splitComplexBuffer = DSPSplitComplex(fromInputArray: input, realParts: &real, imaginaryParts: &imag)

        
        // even though there are 2 real and 2 imaginary output elements, we still need to ask the fft to process 4 input samples
        vDSP_fft_zrip(fftSetup, &splitComplexBuffer, 1, vDSP_Length(log2n), FFTDirection(FFT_FORWARD))

        // zrip results are 2x the standard FFT and need to be scaled
        var scaleFactor = Float(1.0/2.0)
        vDSP_vsmul(splitComplexBuffer.realp, 1, &scaleFactor, splitComplexBuffer.realp, 1, vDSP_Length(halfLength))
        vDSP_vsmul(splitComplexBuffer.imagp, 1, &scaleFactor, splitComplexBuffer.imagp, 1, vDSP_Length(halfLength))
        
        return (real, imag)
        
    }
}

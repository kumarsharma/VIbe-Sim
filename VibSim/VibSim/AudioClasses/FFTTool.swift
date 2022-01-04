//
//  FFTTool.swift
//  VibSim
//
//  Created by KS on 04/01/22.
//

import Foundation
import Accelerate

class FFTTool {
    
    func fft(input: [Float32]) -> ([Float], [Float]) {
        
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
    
    func acc_to_vel(acc_data: [Float32], SR: Int, coeff: Int, HPf: Int) -> ([Float], [Float]) {
        
        let BS = acc_data.count
        let tick = SR/BS
        let HP_lines = Int(HPf/tick) //converts Hertz to spectrum lines
        let acc_fft = fft(input: acc_data) //np.fft.rfft(acc_data)
        let FS = acc_fft.0.count + acc_fft.1.count
//        let vel_fft = np.zeros(FS) + 1j*np.zeros(FS)
//            for i in np.arange(FS):  
//                if i > HP_lines: # this applies the HP filter
//                    vel_fft[i] = coeff*acc_fft[i]/(1j*2.0*np.pi*i*tick)        
//            vel_wave = np.real(np.fft.irfft(vel_fft))
        return ([], [])
    }
}

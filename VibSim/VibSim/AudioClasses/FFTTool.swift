//
//  FFTTool.swift
//  VibSim
//
//  Created by KS on 04/01/22.
//

import Foundation
import Accelerate

class FFTTool {
    
    let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)

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
    
    func acc_to_vel(acc_data: UnsafeMutablePointer<Float>, SR: Int, coeff: Float, HPf: Int, BS: Int) -> ([Float], [Float]) {
        
        let mtick = SR/BS
        let HP_lines = Int(HPf/mtick) //converts Hertz to spectrum lines
//        let acc_fft = fft(input: acc_data) //np.fft.rfft(acc_data)
        let acc_fft =  SignalProcessing.fft(data: acc_data, setup: fftSetup!)
        
        let acc_fft_abs = acc_fft.map { abs($0)/Float((BS/2)) }
        let acc_fft_rms = acc_fft_abs.map { 0.7071 * ($0)}
        
        var vel_fft: [Float] = [] 
        
        for i in 0..<acc_fft_rms.count {
            
            if i>HP_lines {
                
                let val = acc_fft_rms[i]            
                let val2 = (coeff * val)/Float((Int(1.i) * Int(2.0 * Double.pi) * i * Int(mtick)))
                vel_fft.append(val2)
            }
        }
        
        let vel_fft_abs = vel_fft.map { abs($0)/Float((BS/2)) }
        let vel_fft_rms = vel_fft_abs.map { 0.7071 * ($0)}
        
        return (acc_fft_rms, vel_fft_rms)
    }
    
    func toFFT(signal: [Float32]) -> [Float] {
        
//        let signal: [Float] = [0, 1, 2, 3, 4, 5, 6, 7]
        let complexValuesCount = signal.count / 2

        var complexReals = [Float]()
        var complexImaginaries = [Float]()

        signal.withUnsafeBytes { signalPtr in
            complexReals = [Float](unsafeUninitializedCapacity: complexValuesCount) {
                realBuffer, realInitializedCount in
                
                complexImaginaries = [Float](unsafeUninitializedCapacity: complexValuesCount) {
                    imagBuffer, imagInitializedCount in
                    
                    var splitComplex = DSPSplitComplex(realp: realBuffer.baseAddress!,
                                                       imagp: imagBuffer.baseAddress!)
                    
                    vDSP_ctoz([DSPComplex](signalPtr.bindMemory(to: DSPComplex.self)), 2,
                              &splitComplex, 1,
                              vDSP_Length(complexValuesCount))
                    
                    imagInitializedCount = complexValuesCount
                }
                realInitializedCount = complexValuesCount
            }
        }
        
        return complexImaginaries
    }
}

/*
for i in 0..<acc_fft_rms.count {
    
    let val = acc_fft_rms[i]
    dataArray3?.append(val)
    
    if i>HP_lines {
        let val2 = (Float(coeff) * val)/Float((Int(2.0 * Double.pi) * i * Int(mtick)))
        vel_fft.append(val2)
    }
}

let vel_fft_abs = vel_fft.map { abs($0)/Float((BS!/2)) }
let vel_fft_rms = vel_fft_abs.map { 0.7071 * ($0)}

for i in 0..<vel_fft_rms.count {
    
    let val = vel_fft_rms[i]
    dataArray2?.append(val)
}*/

//
//  DCRejectionFilter.swift
//  VibSim
//
//  Created by KS on 24/12/21.
//

import Foundation
import AudioToolbox

class DCRejectionFilter {

    private var mY1: Float32 = 0.0
    private var mX1: Float32 = 0.0
    
    private final let kDefaultPoleDist: Float32 = 0.975
    
    func processInplace(_ ioData: UnsafeMutablePointer<Float32>, numFrames: UInt32) {
        for i in 0..<Int(numFrames) {
            let xCurr = ioData[i]
            ioData[i] = ioData[i] - mX1 + (kDefaultPoleDist * mY1)
            mX1 = xCurr
            mY1 = ioData[i]
        }
    }
}


//
//  BufferManager.swift
//  VibSim
//
//  Created by KS on 24/12/21.
//

import Foundation
import AudioToolbox
import libkern
import TabularData
import Accelerate

let kNumDrawBuffers = 12
let kDefaultDrawSamples = 1024
let kBufferBlockSize = 4096

protocol BufferDelegate {
    
    func didReceiveDataSignal(buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>)
}

class BufferManager {
    
    var displayMode: VSAudioController.aurioTouchDisplayMode
    
    
    private(set) var drawBuffers: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>
    
    var currentDrawBufferLength: Int
    var bufferLength: Int
    
    var hasNewFFTData: Bool {return mHasNewFFTData != 0}
    var needsNewFFTData: Bool {return mNeedsNewFFTData != 0}
    
    var FFTOutputBufferLength: Int {return mFFTInputBufferLen / 2}
    
    private var mDrawBufferIndex: Int
    
    private var mFFTInputBuffer: UnsafeMutablePointer<Float32>?
    private var mFFTInputBufferFrameIndex: Int
    private var mFFTInputBufferLen: Int
    private var mHasNewFFTData: Int32   //volatile
    private var mNeedsNewFFTData: Int32 //volatile
    
    var mFFTHelper: FFTHelper
    
    var bufferDelegate: BufferDelegate?
    
    init(maxFramesPerSlice inMaxFramesPerSlice: Int) {
        displayMode = .oscilloscopeWaveform
        drawBuffers = UnsafeMutablePointer.allocate(capacity: Int(kNumDrawBuffers))
        mDrawBufferIndex = 0
        currentDrawBufferLength = kDefaultDrawSamples
        mFFTInputBuffer = nil
        mFFTInputBufferFrameIndex = 0
        mFFTInputBufferLen = inMaxFramesPerSlice
        mHasNewFFTData = 0
        mNeedsNewFFTData = 0
        bufferLength = 0
        for i in 0..<kNumDrawBuffers {
            drawBuffers[Int(i)] = UnsafeMutablePointer.allocate(capacity: Int(inMaxFramesPerSlice))
        }
        
        mFFTInputBuffer = UnsafeMutablePointer.allocate(capacity: Int(inMaxFramesPerSlice))
        mFFTHelper = FFTHelper(maxFramesPerSlice: inMaxFramesPerSlice)
        OSAtomicIncrement32Barrier(&mNeedsNewFFTData)
    }
    
    
    deinit {
        for i in 0..<kNumDrawBuffers {
            drawBuffers[Int(i)]?.deallocate()
            drawBuffers[Int(i)] = nil
        }
        drawBuffers.deallocate()
        
        mFFTInputBuffer?.deallocate()
    }
    
    
    func copyAudioDataToDrawBuffer(_ inData: UnsafePointer<Float32>?, inNumFrames: Int, dataSize: UInt32) {
        if inData == nil { return }
        
        /*
        for i in 0..<inNumFrames {
            if i + mDrawBufferIndex >= currentDrawBufferLength {
                cycleDrawBuffers()
                mDrawBufferIndex = -i
            }
            drawBuffers[0]?[i + mDrawBufferIndex] = (inData?[i])!
        }
        mDrawBufferIndex += inNumFrames*/
        
        let readFromCSV = true
        
        if readFromCSV {
            //read from CSV as simulated data
            let url = Bundle.main.url(forResource: "acc_TWF", withExtension: "csv")!
            if #available(iOS 15, *) {
                let result = try? DataFrame(contentsOfCSVFile: url) as DataFrame
                bufferLength = (result?.rows.count)!
                for i in 0..<bufferLength {
                    
                    drawBuffers[0]?[i] = Float32((result?.rows[i][0])! as! Double)
                }
    //            print(result)
            } else {
                // Fallback on earlier versions
            }
        }
        else {
            
            for i in 0..<inNumFrames {
                if i + mDrawBufferIndex >= currentDrawBufferLength {
                    cycleDrawBuffers()
                    mDrawBufferIndex = -i
                }
                drawBuffers[0]?[i + mDrawBufferIndex] = (inData?[i])!
            }
            mDrawBufferIndex += inNumFrames            
        }
        
        self.bufferDelegate?.didReceiveDataSignal(buffer: drawBuffers)
    }
    
    
    func cycleDrawBuffers() {
        // Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
        for drawBuffer_i in stride(from: (kNumDrawBuffers - 2), through: 0, by: -1) {
            memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], size_t(currentDrawBufferLength))
        }
    }
    
    
    func CopyAudioDataToFFTInputBuffer(_ inData: UnsafePointer<Float32>, numFrames: Int) {
        let framesToCopy = min(numFrames, mFFTInputBufferLen - mFFTInputBufferFrameIndex)
        memcpy(mFFTInputBuffer?.advanced(by: mFFTInputBufferFrameIndex), inData, size_t(framesToCopy * MemoryLayout<Float32>.size))
        mFFTInputBufferFrameIndex += framesToCopy * MemoryLayout<Float32>.size
        if mFFTInputBufferFrameIndex >= mFFTInputBufferLen {
            OSAtomicIncrement32(&mHasNewFFTData)
            OSAtomicDecrement32(&mNeedsNewFFTData)
        }
    }
    
    
    func GetFFTOutput(_ outFFTData: UnsafeMutablePointer<Float32>) {
        mFFTHelper.computeFFT(mFFTInputBuffer, outFFTData: outFFTData)
        mFFTInputBufferFrameIndex = 0
        OSAtomicDecrement32Barrier(&mHasNewFFTData)
        OSAtomicIncrement32Barrier(&mNeedsNewFFTData)
    }
}


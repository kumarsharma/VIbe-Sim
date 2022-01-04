//
//  VSMeasurementController.swift
//  VibSim
//
//  Created by Kumar Sharma on 24/12/21.
//

import UIKit
import NChart3D

let ChartKey = "erUfZqFAB/6KSR9tEK41MKq9eISHR7a/HAdkw4GG3G95/wCaOur1jOACdLLmiJfscEimwSlaPte5 xggUT3hVstd1u1x/dHnWuO1Jyochyd1RI8PKGg5DwFWlDAB9C5AKs/+HCdxllydZUdHOW93sRhRr hbnvYYgzaEaiDDZWWxxWwB2gNZavtfEVzOKiurSRBNmhBuk7SZKu0l3CxNeYM7nYTVh3SJhV9b1P BWifrcQOr7MGPjHXI2jN2vmqcIbqylar0dH5ZMYsgIIlZhGzUPswGwWFY6MdwZ9jp0hHCzyWMlid 9p9g5dXaemDlvwbr+FY2MGgGjPB+9EOECfD9Srf4IX+L6xMY5aUlU3Zkv2xS98PymH8lYhQFLxik smlaElBTNZYDiJNS3tiWIsAjXFlfnSAQUzPRFgQb8BIDEnOckWVr2SCe77S+oCo1BccaKCN2JqEp 36sibNGz+hPtUpkoXd53MD3hlscB3Kkm/VWj/inOwbRGjXi9ngmJVgvkWGkZoZe4eI8Ne0hlOmfY tzBwa22YLWN1E8CEZ/J1Y30YblDbmOIWW6fnCtiUtvY/7bldJNL375KZBrw0P6hUuasGlm0P12er 9cEhbKhRYBHsmZsqZYXv7fwJXxefSobgnLcMsMFEbGALOa2GKGeJZNDPDWVYtrAsWHHNCt/Ls94="

class VSMeasurementController: UIViewController {
    
    @IBOutlet var TWFPlotView: UIView?
    @IBOutlet var FFTPlotView: UIView?
    
    var TWFChartView: NChartView?
    var FFTChartView: NChartView?
    var audioController: VSAudioController?    
    var dataArray: [Float32]?
    var dataArray2: [Float32?]?
    var dataArray3: [Float32?]?
    
    let max = GLfloat(kDefaultDrawSamples)
    private var animationStarted: TimeInterval = 0
    private var animationTimer: Timer?
    private var animationInterval: TimeInterval = 0
    var l_fftData: UnsafeMutablePointer<Float32>!

    func CLAMP<T: Comparable>(_ min: T, _ x: T, _ max: T) -> T {return x < min ? min : (x > max ? max : x)}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioController = VSAudioController()
        audioController?.bufferManagerInstance.bufferDelegate = self
        
        l_fftData = UnsafeMutablePointer.allocate(capacity: audioController!.bufferManagerInstance.FFTOutputBufferLength)
        bzero(l_fftData, size_t(audioController!.bufferManagerInstance.FFTOutputBufferLength * MemoryLayout<Float32>.size))

        self.loadTWFChartView()
        self.loadFFTChartView()
        
        /*
        animationTimer = Timer.scheduledTimer(timeInterval: animationInterval, target: self, selector: #selector(self.collectDataSignals as () -> ()), userInfo: nil, repeats: true)
        animationTimer?.fire()
        animationStarted = Date.timeIntervalSinceReferenceDate*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        audioController!.startIOUnit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        audioController!.stopIOUnit()
    }

    func loadTWFChartView() {
   
        TWFChartView = NChartView(frame: self.TWFPlotView!.bounds)
        TWFChartView?.chart.licenseKey = "erUfZqFAB/6KSR9tEK41MKq9eISHR7a/HAdkw4GG3G95/wCaOur1jOACdLLmiJfscEimwSlaPte5xggUT3hVstd1u1x/dHnWuO1Jyochyd1RI8PKGg5DwFWlDAB9C5AKs/+HCdxllydZUdHOW93sRhRrhbnvYYgzaEaiDDZWWxxWwB2gNZavtfEVzOKiurSRBNmhBuk7SZKu0l3CxNeYM7nYTVh3SJhV9b1PBWifrcQOr7MGPjHXI2jN2vmqcIbqylar0dH5ZMYsgIIlZhGzUPswGwWFY6MdwZ9jp0hHCzyWMlid9p9g5dXaemDlvwbr+FY2MGgGjPB+9EOECfD9Srf4IX+L6xMY5aUlU3Zkv2xS98PymH8lYhQFLxiksmlaElBTNZYDiJNS3tiWIsAjXFlfnSAQUzPRFgQb8BIDEnOckWVr2SCe77S+oCo1BccaKCN2JqEp36sibNGz+hPtUpkoXd53MD3hlscB3Kkm/VWj/inOwbRGjXi9ngmJVgvkWGkZoZe4eI8Ne0hlOmfYtzBwa22YLWN1E8CEZ/J1Y30YblDbmOIWW6fnCtiUtvY/7bldJNL375KZBrw0P6hUuasGlm0P12er9cEhbKhRYBHsmZsqZYXv7fwJXxefSobgnLcMsMFEbGALOa2GKGeJZNDPDWVYtrAsWHHNCt/Ls94="
        TWFChartView?.licenseKey = "erUfZqFAB/6KSR9tEK41MKq9eISHR7a/HAdkw4GG3G95/wCaOur1jOACdLLmiJfscEimwSlaPte5xggUT3hVstd1u1x/dHnWuO1Jyochyd1RI8PKGg5DwFWlDAB9C5AKs/+HCdxllydZUdHOW93sRhRrhbnvYYgzaEaiDDZWWxxWwB2gNZavtfEVzOKiurSRBNmhBuk7SZKu0l3CxNeYM7nYTVh3SJhV9b1PBWifrcQOr7MGPjHXI2jN2vmqcIbqylar0dH5ZMYsgIIlZhGzUPswGwWFY6MdwZ9jp0hHCzyWMlid9p9g5dXaemDlvwbr+FY2MGgGjPB+9EOECfD9Srf4IX+L6xMY5aUlU3Zkv2xS98PymH8lYhQFLxiksmlaElBTNZYDiJNS3tiWIsAjXFlfnSAQUzPRFgQb8BIDEnOckWVr2SCe77S+oCo1BccaKCN2JqEp36sibNGz+hPtUpkoXd53MD3hlscB3Kkm/VWj/inOwbRGjXi9ngmJVgvkWGkZoZe4eI8Ne0hlOmfYtzBwa22YLWN1E8CEZ/J1Y30YblDbmOIWW6fnCtiUtvY/7bldJNL375KZBrw0P6hUuasGlm0P12er9cEhbKhRYBHsmZsqZYXv7fwJXxefSobgnLcMsMFEbGALOa2GKGeJZNDPDWVYtrAsWHHNCt/Ls94="
        TWFChartView?.chart.cartesianSystem.margin = NChartMarginMake(10.0, 10.0, 10.0, 20.0)
        for _ in 0..<2 {
            let series = NChartLineSeries()
            series.dataSource = self
            series.tag = 100
            series.lineThickness = 1.0
            series.brush = NChartSolidColorBrush(color: UIColor(red: 0.38, green: 0.8, blue: 0.91, alpha: 1.0))
            TWFChartView?.chart.addSeries(series)
        }
        TWFChartView?.chart.cartesianSystem.xAxis.shouldBeautifyMinAndMax = true
        TWFChartView?.chart.cartesianSystem.yAxis.shouldBeautifyMinAndMax = true
    //    TWFChartView?.chart.streamingMode = YES;
        TWFChartView?.chart.pointSelectionEnabled = false
        TWFChartView?.chart.cartesianSystem.xAxis.hasOffset = true
        TWFChartView?.chart.cartesianSystem.yAxis.hasOffset = false
    //    TWFChartView?.chart.cartesianSystem.zAxis.hasOffset = NO;
        TWFChartView?.chart.cartesianSystem.borderColor = .gray
        TWFChartView?.chart.cartesianSystem.xAxis.majorTicks.color = .clear
        TWFChartView?.chart.cartesianSystem.xAxis.minorTicks.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        
        TWFChartView?.chart.cartesianSystem.yAxis.majorTicks.color = .clear
        TWFChartView?.chart.cartesianSystem.yAxis.minorTicks.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        TWFChartView?.chart.cartesianSystem.xAlongY.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        TWFChartView?.chart.cartesianSystem.yAlongX.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        TWFChartView?.chart.cartesianSystem.xAxis.textColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1) 
        TWFChartView?.chart.cartesianSystem.yAxis.textColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1) 
        TWFChartView?.chart.cartesianSystem.xAxis.caption.textColor = .gray
        TWFChartView?.chart.cartesianSystem.yAxis.caption.textColor = .gray
        TWFChartView?.chart.cartesianSystem.xAxis.font = UIFont.systemFont(ofSize: 11)
        TWFChartView?.chart.cartesianSystem.yAxis.font = UIFont.systemFont(ofSize: 11)
        TWFChartView?.chart.cartesianSystem.xAxis.caption.font = UIFont.systemFont(ofSize: 14)
        TWFChartView?.chart.cartesianSystem.yAxis.caption.font = UIFont.systemFont(ofSize: 14)

//        TWFChartView?.chart.cartesianSystem.autoAxesIntersectionValue = false
//        TWFChartView?.chart.cartesianSystem.axesIntersectionValue = NChartVector3Make(0.0, 0.0, 0.0)
        TWFChartView?.chart.cartesianSystem.yAxis.lineVisible = true
        TWFChartView?.chart.cartesianSystem.xAxis.lineVisible = true

        TWFChartView?.chart.zoomMode = .directional
        TWFChartView?.chart.userInteractionMode = NChartUserInteraction.horizontalZoom.rawValue ^ NChartUserInteraction.horizontalMove.rawValue
        
        self.TWFPlotView?.addSubview(TWFChartView!)
        TWFChartView?.chart.updateSeries()
    }
    
    func loadFFTChartView() {
   
        FFTChartView = NChartView(frame: self.FFTPlotView!.bounds)
        FFTChartView?.chart.licenseKey = "erUfZqFAB/6KSR9tEK41MKq9eISHR7a/HAdkw4GG3G95/wCaOur1jOACdLLmiJfscEimwSlaPte5xggUT3hVstd1u1x/dHnWuO1Jyochyd1RI8PKGg5DwFWlDAB9C5AKs/+HCdxllydZUdHOW93sRhRrhbnvYYgzaEaiDDZWWxxWwB2gNZavtfEVzOKiurSRBNmhBuk7SZKu0l3CxNeYM7nYTVh3SJhV9b1PBWifrcQOr7MGPjHXI2jN2vmqcIbqylar0dH5ZMYsgIIlZhGzUPswGwWFY6MdwZ9jp0hHCzyWMlid9p9g5dXaemDlvwbr+FY2MGgGjPB+9EOECfD9Srf4IX+L6xMY5aUlU3Zkv2xS98PymH8lYhQFLxiksmlaElBTNZYDiJNS3tiWIsAjXFlfnSAQUzPRFgQb8BIDEnOckWVr2SCe77S+oCo1BccaKCN2JqEp36sibNGz+hPtUpkoXd53MD3hlscB3Kkm/VWj/inOwbRGjXi9ngmJVgvkWGkZoZe4eI8Ne0hlOmfYtzBwa22YLWN1E8CEZ/J1Y30YblDbmOIWW6fnCtiUtvY/7bldJNL375KZBrw0P6hUuasGlm0P12er9cEhbKhRYBHsmZsqZYXv7fwJXxefSobgnLcMsMFEbGALOa2GKGeJZNDPDWVYtrAsWHHNCt/Ls94="
        FFTChartView?.licenseKey = "erUfZqFAB/6KSR9tEK41MKq9eISHR7a/HAdkw4GG3G95/wCaOur1jOACdLLmiJfscEimwSlaPte5xggUT3hVstd1u1x/dHnWuO1Jyochyd1RI8PKGg5DwFWlDAB9C5AKs/+HCdxllydZUdHOW93sRhRrhbnvYYgzaEaiDDZWWxxWwB2gNZavtfEVzOKiurSRBNmhBuk7SZKu0l3CxNeYM7nYTVh3SJhV9b1PBWifrcQOr7MGPjHXI2jN2vmqcIbqylar0dH5ZMYsgIIlZhGzUPswGwWFY6MdwZ9jp0hHCzyWMlid9p9g5dXaemDlvwbr+FY2MGgGjPB+9EOECfD9Srf4IX+L6xMY5aUlU3Zkv2xS98PymH8lYhQFLxiksmlaElBTNZYDiJNS3tiWIsAjXFlfnSAQUzPRFgQb8BIDEnOckWVr2SCe77S+oCo1BccaKCN2JqEp36sibNGz+hPtUpkoXd53MD3hlscB3Kkm/VWj/inOwbRGjXi9ngmJVgvkWGkZoZe4eI8Ne0hlOmfYtzBwa22YLWN1E8CEZ/J1Y30YblDbmOIWW6fnCtiUtvY/7bldJNL375KZBrw0P6hUuasGlm0P12er9cEhbKhRYBHsmZsqZYXv7fwJXxefSobgnLcMsMFEbGALOa2GKGeJZNDPDWVYtrAsWHHNCt/Ls94="
        FFTChartView?.chart.cartesianSystem.margin = NChartMarginMake(10.0, 10.0, 10.0, 20.0)
        for _ in 0..<2 {
            let series = NChartLineSeries()
            series.dataSource = self
            series.tag = 200
            series.lineThickness = 1.0
            series.brush = NChartSolidColorBrush(color: UIColor(red: 0.38, green: 0.8, blue: 0.91, alpha: 1.0))
            FFTChartView?.chart.addSeries(series)
        }
        FFTChartView?.chart.cartesianSystem.xAxis.shouldBeautifyMinAndMax = true
        FFTChartView?.chart.cartesianSystem.yAxis.shouldBeautifyMinAndMax = true
    //    TWFChartView?.chart.streamingMode = YES;
        FFTChartView?.chart.pointSelectionEnabled = false
        FFTChartView?.chart.cartesianSystem.xAxis.hasOffset = true
        FFTChartView?.chart.cartesianSystem.yAxis.hasOffset = false
    //    TWFChartView?.chart.cartesianSystem.zAxis.hasOffset = NO;
        FFTChartView?.chart.cartesianSystem.borderColor = .gray
        FFTChartView?.chart.cartesianSystem.xAxis.majorTicks.color = .clear
        FFTChartView?.chart.cartesianSystem.xAxis.minorTicks.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        
        FFTChartView?.chart.cartesianSystem.yAxis.majorTicks.color = .clear
        FFTChartView?.chart.cartesianSystem.yAxis.minorTicks.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        FFTChartView?.chart.cartesianSystem.xAlongY.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        FFTChartView?.chart.cartesianSystem.yAlongX.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) 
        FFTChartView?.chart.cartesianSystem.xAxis.textColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1) 
        FFTChartView?.chart.cartesianSystem.yAxis.textColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1) 
        FFTChartView?.chart.cartesianSystem.xAxis.caption.textColor = .gray
        FFTChartView?.chart.cartesianSystem.yAxis.caption.textColor = .gray
        FFTChartView?.chart.cartesianSystem.xAxis.font = UIFont.systemFont(ofSize: 11)
        FFTChartView?.chart.cartesianSystem.yAxis.font = UIFont.systemFont(ofSize: 11)
        FFTChartView?.chart.cartesianSystem.xAxis.caption.font = UIFont.systemFont(ofSize: 14)
        FFTChartView?.chart.cartesianSystem.yAxis.caption.font = UIFont.systemFont(ofSize: 14)

//        TWFChartView?.chart.cartesianSystem.autoAxesIntersectionValue = false
//        TWFChartView?.chart.cartesianSystem.axesIntersectionValue = NChartVector3Make(0.0, 0.0, 0.0)
        FFTChartView?.chart.cartesianSystem.yAxis.lineVisible = true
        FFTChartView?.chart.cartesianSystem.xAxis.lineVisible = true

        FFTChartView?.chart.zoomMode = .directional
        FFTChartView?.chart.userInteractionMode = NChartUserInteraction.horizontalZoom.rawValue ^ NChartUserInteraction.horizontalMove.rawValue
        
        self.FFTPlotView?.addSubview(FFTChartView!)
        FFTChartView?.chart.updateSeries()
    }
    
    @objc func collectDataSignals_() {
        
//        if self.applicationResignedActive { return }
        
//        self.collectSignals(self, forTime: Date.timeIntervalSinceReferenceDate - animationStarted)
    }
    
    private func collectDataSignals(buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>) {
        if !audioController!.audioChainIsBeingReconstructed {  //hold off on drawing until the audio chain has been reconstructed
            
            let bufferManager = audioController!.bufferManagerInstance
            let drawBuffers = buffer
            var drawBuffer_ptr: UnsafeMutablePointer<Float32>
            dataArray = [] //acc_TWF
            dataArray2 = [] //vel_fft_rms
            dataArray3 = [] //acc_fft_rms
            
            for drawBuffer_i in 0..<bufferManager.bufferLength {
//                if drawBuffers[drawBuffer_i] == nil { continue }
                
                let val = drawBuffers[0]![drawBuffer_i]
                dataArray!.append(val)
            }
            
            let SR = 44100 as UInt32 //5120 * 2 as UInt32
            let coeff = 386.08858
            audioController?.bufferManagerInstance.GetFFTOutput(l_fftData)
            let maxY = audioController?.bufferManagerInstance.currentDrawBufferLength
            let fftLength = audioController?.bufferManagerInstance.FFTOutputBufferLength
            
            let acc_fft = audioController?.bufferManagerInstance.mFFTHelper.getFFT(input: dataArray!)
            
            let pointerToFloats = UnsafeMutablePointer<Float>.allocate(capacity: dataArray!.count)
            pointerToFloats.assign(from: dataArray!, count: dataArray!.count)

            /*
            let acc_fft2 = VSFFT.fft(pointerToFloats, logFFTsize: 2)
            var real_ptr: UnsafeMutablePointer<Double>
            real_ptr = acc_fft2.realp
            for drawBuffer_i in 0..<4096 {

                let val = real_ptr.pointee
                dataArray2!.append(Float(val))
                real_ptr += 1
            }*/
            
            let BS = 4096 as UInt32
            let mtick = SR/BS
            let HP_lines = Int(2/mtick)

            
            for i in 0..<acc_fft!.1.count {
                
                if i>HP_lines {
                    
                    let realVal = (Float(coeff) * (acc_fft?.0[i])!)/Float((Int(2.0 * Double.pi) * i * Int(mtick)))
                    let imagVal = (Float(-1*coeff) * (acc_fft?.1[i])!)/Float((Int(2.0 * Double.pi) * i * Int(mtick)))
                    dataArray2!.append(realVal)
                    dataArray3!.append(imagVal)
                }
            }      
            TWFChartView?.chart.updateData()
            FFTChartView?.chart.updateData()
        }
    }
}

extension VSMeasurementController: NChartSeriesDataSource {
    
    func seriesDataSourcePoints(for series: NChartSeries!) -> [Any]! {
        
        var result = [NChartPoint]()
        
        if series.tag == 100 {
            
            for i in 0..<dataArray!.count {
                result.append(NChartPoint(state: NChartPointState(alignedToXWithX: i, y: Double(dataArray![i])),
                    for: series))
            }
        } else if series.tag == 200 {
            
            for i in 0..<dataArray2!.count {
                result.append(NChartPoint(state: NChartPointState(alignedToXWithX: i, y: Double(dataArray2![i]!)),
                    for: series))
            }
        }
        return result
    }
    
    func seriesDataSourceName(for series: NChartSeries!) -> String! {
        
//        return "My series"
        return nil
    }
}

extension VSMeasurementController: BufferDelegate {
    
    func didReceiveDataSignal(buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>) {
        
        self.collectDataSignals(buffer: buffer)
    }
}

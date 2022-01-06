//
//  VSMeasurementController.swift
//  VibSim
//
//  Created by Kumar Sharma on 24/12/21.
//

import UIKit
import NChart3D
import TabularData

let ChartKey = "erUfZqFAB/6KSR9tEK41MKq9eISHR7a/HAdkw4GG3G95/wCaOur1jOACdLLmiJfscEimwSlaPte5 xggUT3hVstd1u1x/dHnWuO1Jyochyd1RI8PKGg5DwFWlDAB9C5AKs/+HCdxllydZUdHOW93sRhRr hbnvYYgzaEaiDDZWWxxWwB2gNZavtfEVzOKiurSRBNmhBuk7SZKu0l3CxNeYM7nYTVh3SJhV9b1P BWifrcQOr7MGPjHXI2jN2vmqcIbqylar0dH5ZMYsgIIlZhGzUPswGwWFY6MdwZ9jp0hHCzyWMlid 9p9g5dXaemDlvwbr+FY2MGgGjPB+9EOECfD9Srf4IX+L6xMY5aUlU3Zkv2xS98PymH8lYhQFLxik smlaElBTNZYDiJNS3tiWIsAjXFlfnSAQUzPRFgQb8BIDEnOckWVr2SCe77S+oCo1BccaKCN2JqEp 36sibNGz+hPtUpkoXd53MD3hlscB3Kkm/VWj/inOwbRGjXi9ngmJVgvkWGkZoZe4eI8Ne0hlOmfY tzBwa22YLWN1E8CEZ/J1Y30YblDbmOIWW6fnCtiUtvY/7bldJNL375KZBrw0P6hUuasGlm0P12er 9cEhbKhRYBHsmZsqZYXv7fwJXxefSobgnLcMsMFEbGALOa2GKGeJZNDPDWVYtrAsWHHNCt/Ls94="

class VSMeasurementController: UIViewController {
    
    @IBOutlet var TWFPlotView: UIView?
    @IBOutlet var FFTPlotView: UIView?
    
    var TWFChartView: NChartView?
    var FFTChartView: NChartView?
    var audioController: VSAudioController?    
    var acc_TWF: [Float32]? = [Float32](repeating: 0, count: 32768)
    var acc_TWF2: [Float32]? = [Float32](repeating: 0, count: 32768)
    var acc_fft_rms: [Float32]? = [Float32](repeating: 0, count: 32768)
    var vel_fft_rms: [Float32]? = [Float32](repeating: 0, count: 32768)
    var vel_TWF: [Float32?]?
    var fftTool: FFTTool?
    
    var microphone: VibedataInput?
    var flagMeasured: Int? = 0
    var seriesNumber: Int? = 0
    var tryLoad: Int? = 0
    var overallCalValue: Double = 0
    var calibrationFactor: Double = 1
    var SensorMultiplier: Double = 1
    var BinMultiplier: Int? = 1
    var flagChart: Int? = 0
    var frequencyUnits: Int? = 0
    var Resolution: Double? = 0
    var tempRPMvalue: Double? = 0
    var integrationVar: Int? = 0
    var amplitudeUnits: Int? = 0
    var velRmsPeakInd: Double? = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Vibration Analyzer View"
        
        externSampleRate = 48000
        self.microphone = VibedataInput(microphoneDelegate: self, startsImmediately: true)
        
        fftTool = FFTTool()
//        audioController = VSAudioController()
//        audioController?.bufferManagerInstance.bufferDelegate = self
        
        self.loadTWFChartView()
        self.loadFFTChartView()
        TWFChartView?.chart.cartesianSystem.xAxis.dataSource = self
        TWFChartView?.chart.cartesianSystem.yAxis.dataSource = self
        FFTChartView?.chart.cartesianSystem.xAxis.dataSource = self
        FFTChartView?.chart.cartesianSystem.yAxis.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        audioController!.startIOUnit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
//        audioController!.stopIOUnit()
    }
    
    @objc func measureNext() {
        
        seriesNumber = 0
        flagMeasured = 0
        
//        audioController!.startIOUnit()
        
        if microphone == nil {
            
            self.microphone = VibedataInput(microphoneDelegate: self, startsImmediately: true)
            self.changeAUSRstart()
        }
    }
    
    @IBAction func changeAUSRstart() {
        
        self.microphone?.changeAUSR()
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
    
    @IBAction func plotAction() {

        let flagConnected = VibedataInput.getFlagConnected()
        /*
        if (flagConnected == 0) {
            [labelConnected setTintColor: [UIColor redColor]];
            labelConnected.enabled = YES;
            labelConnected.title = @"No Device Connected";
        }
        else if (flagConnected == 1) {
            [labelConnected setTintColor: [UIColor blackColor]];
            labelConnected.enabled = NO;
            labelConnected.title = @"Signal from GTI-220";
        }
        else if (flagConnected == 2) {
            [labelConnected setTintColor: [UIColor blackColor]];
            labelConnected.enabled = NO;
            labelConnected.title = @"Signal from GTI-120";
        }
        else if (flagConnected == 3) {
            [labelConnected setTintColor: [UIColor blackColor]];
            labelConnected.enabled = NO;
            labelConnected.title = @"Signal from GTI-120";
        }
        else if (flagConnected == 4) {
            [labelConnected setTintColor: [UIColor blackColor]];
            labelConnected.enabled = NO;
            labelConnected.title = @"Signal from GTI-110";
        }
        else if (flagConnected == 10) {
            [labelConnected setTintColor: [UIColor blackColor]];
            labelConnected.enabled = NO;
            labelConnected.title = @"Hardware not Recognized";
        }*/
        
        /*
        if ((flagConnected != 0)&&(flagConnected != 10)) {
            m_view.chart.cartesianSystem.xAxis.dataSource = self;
            m_view.chart.cartesianSystem.yAxis.dataSource = self;
            flagChart = 1;
            [m_view.chart updateData];
            
            if (flagTWFPlotOption == 1) {
                m_viewCTWF.chart.cartesianSystem.xAxis.dataSource = self;
                m_viewCTWF.chart.cartesianSystem.yAxis.dataSource = self;
    //            flagChart = 3;
                [m_viewCTWF.chart updateData];
            }
            
            [self processFFT];
            m_viewFFT.chart.cartesianSystem.xAxis.dataSource = self;
            m_viewFFT.chart.cartesianSystem.yAxis.dataSource = self;
            flagChart = 2;
            [m_viewFFT.chart updateData];
        }*/

        if flagConnected != 0 && flagConnected != 10 {
            
            TWFChartView?.chart.cartesianSystem.xAxis.dataSource = self
            TWFChartView?.chart.cartesianSystem.yAxis.dataSource = self
            flagChart = 1
            TWFChartView?.chart.updateData()
            
            /*
            if (flagTWFPlotOption == 1) {
                m_viewCTWF.chart.cartesianSystem.xAxis.dataSource = self;
                m_viewCTWF.chart.cartesianSystem.yAxis.dataSource = self;
    //            flagChart = 3;
                [m_viewCTWF.chart updateData];
            }*/
            
            
            
            FFTChartView?.chart.cartesianSystem.xAxis.dataSource = self
            FFTChartView?.chart.cartesianSystem.yAxis.dataSource = self
        }
    }
    
    @objc func collectDataSignals_() {
    
    }
    
    private func collectDataSignals(buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>) {
        if !audioController!.audioChainIsBeingReconstructed {  //hold off on drawing until the audio chain has been reconstructed
            
            let bufferManager = audioController!.bufferManagerInstance
            let drawBuffers = buffer
            var drawBuffer_ptr = drawBuffers[0]
            acc_TWF = [] //acc_TWF
            acc_fft_rms = [] //vel_fft_rms
            vel_fft_rms = [] //acc_fft_rms
            flagChart = 1
            
            for drawBuffer_i in 0..<bufferManager.bufferLength {
//                if drawBuffers[drawBuffer_i] == nil { continue }
                
                let val = drawBuffers[0]![drawBuffer_i]
                acc_TWF!.append(val)
            }
            TWFChartView?.chart.updateData()
            
            let loadFromCSV = false
            
            if loadFromCSV {
                
                acc_fft_rms = self.loadTest_Acc_FFT_Rms()
                vel_fft_rms = self.loadTest_Vel_FFT_Rms()
                
            } else {
                
                let SR = 44100 as Int
                let coeff = 386.08858 as Float
                let BS = audioController?.bufferManagerInstance.bufferLength

                let spectra = fftTool?.acc_to_vel(acc_data: drawBuffer_ptr!, SR: SR, coeff: coeff, HPf: 2, BS: BS!)
                acc_fft_rms = spectra!.0
                vel_fft_rms = spectra!.1           
            }
            
            flagChart = 2
            FFTChartView?.chart.updateData()
        }
    }
    
    private func loadTest_Vel_FFT_Rms() -> [Float] {
        
        var floats:[Float] = []
        
        let url = Bundle.main.url(forResource: "vel_fft_rms", withExtension: "csv")!
        if #available(iOS 15, *) {
            let result = try? DataFrame(contentsOfCSVFile: url) as DataFrame
            let bufferLength = (result?.rows.count)!
            for i in 0..<bufferLength {
                
                floats.append(Float((result?.rows[i][0])! as! Double))
            }
        }
        return floats
    }
    
    private func loadTest_Acc_FFT_Rms() -> [Float] {
        
        var floats:[Float] = []
        
        let url = Bundle.main.url(forResource: "acc_fft_rms", withExtension: "csv")!
        if #available(iOS 15, *) {
            let result = try? DataFrame(contentsOfCSVFile: url) as DataFrame
            let bufferLength = (result?.rows.count)!
            for i in 0..<bufferLength {
                
                floats.append(Float((result?.rows[i][0])! as! Double))
            }
        }
        return floats
    }
    
}

extension VSMeasurementController: NChartSeriesDataSource {
    
    func seriesDataSourcePoints(for series: NChartSeries!) -> [Any]! {
        
        var result = [NChartPoint]()
        
        if series.tag == 100 {
            
            for i in 0..<acc_TWF!.count {
                result.append(NChartPoint(state: NChartPointState(alignedToXWithX: i, y: Double(acc_TWF![i])),
                    for: series))
            }
        } else if series.tag == 200 {
            
            for i in 0..<acc_fft_rms!.count {
                result.append(NChartPoint(state: NChartPointState(alignedToXWithX: i, y: Double(acc_fft_rms![i])),
                    for: series))
            }
        }
        
        DispatchQueue.main.async { [self] in
            
            self.perform(#selector(measureNext), with: nil, afterDelay: 0.9)
        }
//        self.measureNext()
        return result
    }
    
    func seriesDataSourceName(for series: NChartSeries!) -> String! {
        
        return nil
    }
}

extension VSMeasurementController: NChartValueAxisDataSource {
    
    /*
    func valueAxisDataSourceTicks(for axis: NChartValueAxis!) -> [Any]! {
        
        let numSamples = 4096
        switch axis.kind {
        
        case .X:
            if flagChart == 1 {
                
                var result: [NSString]? = []
                for i in 0..<numSamples {
                    
                    let val = NSString(format: "%2.2f", Double(i)/externSampleRate!)
                    result?.append(val)
                    return result
                }
                
            }
        default:
            return nil
        }
        
        return nil
    }
     */
    
    func valueAxisDataSourceDouble(_ value: Double, toStringFor axis: NChartValueAxis!) -> String! {
        
        var result: String?
        
        switch axis.kind {
        case .X:
            
            if flagChart == 1 {
                
                let step = 1/externSampleRate!
                result = String(format: "%2.2f", step * value)
            }
            else if flagChart == 2 {
                
                switch frequencyUnits {
                    
                    case 0:
                        result = String(format: "%6.0f", value * Resolution! * 60)
                    case 1:
                        result = String(format: "%5.1f", value * Resolution!)
                    case 2:
                        result = String(format: "%3.2f", value * Resolution! * 60)
                    default:
                        result = nil
                }
            }
            
        case .Y:
            result = String(format: "%2.4f", value)
            
        default:
            result = nil
        }
        
        return result
    }
    
    func valueAxisDataSourceName(for axis: NChartValueAxis!) -> String! {
        
        switch axis.kind {
            
            case .X:
                if flagChart == 1 {
                    
                    return "Time (sec)"
                }
                else if flagChart == 2 {
                    if frequencyUnits == 0 {
                        
                        return "Frequency (CPM)"
                    }
                    if frequencyUnits == 1 {
                        
                        return "Frequency (Hz)"
                    }
                    if frequencyUnits == 2 {
                        
                        return "Frequency (Orders)"
                    }
                }
            
            case .Y:
                
                if flagChart == 1 {
                    return "Acceleration (G's)"
                }
                else if flagChart == 2 {
                    
                    if integrationVar == 0 {
                        
    //                    labelOverallRMS.hidden = NO;
    //                    labelOverallRMS.text = @"Overall RMS";
                        return "Acceleration (G's rms)"
                    }
                    if integrationVar == 1 {
                        
    //                    labelOverallRMS.hidden = NO;
                        if amplitudeUnits == 0 {
                            if velRmsPeakInd == 0 {
    //                            labelOverallRMS.text = @"Overall RMS";
                                return "Velocity (ips rms)"
                            }
                            else if velRmsPeakInd == 1 {
    //                            labelOverallRMS.text = @"Overall 0-Pk";
                                return "Velocity (ips 0-Pk)"
                            }
                        }
                        if amplitudeUnits == 1 {
                            
                            if velRmsPeakInd == 0 {
    //                            labelOverallRMS.text = @"Overall RMS";
                                return "Velocity (mm/s rms)"
                            }
                            if velRmsPeakInd == 1 {
                                
    //                            labelOverallRMS.text = @"Overall 0-Pk";
                                return "Velocity (mm/s 0-Pk)"
                            }
                        }
                    }
                    if (integrationVar == 2) {
                        if (amplitudeUnits == 0) {
    //                        labelOverallRMS.hidden = YES;
                            return "Displacement (mils Pk-Pk)"
                        }
                        if (amplitudeUnits == 1) {
    //                        labelOverallRMS.hidden = YES;
                            return "Displacement (µm Pk-Pk)"
                        }
                    }
                }
        
            default:
                return nil            
        }
        
        return nil
    }
    
    
    func valueAxisDataSourceDateStep(for axis: NChartValueAxis!) -> NSNumber! {
        
        if axis.kind == .X {
            
            if (flagChart == 1) {
                
                return NSNumber(floatLiteral: 0.1/Resolution!)
            }
            if (flagChart == 2) {
                
                return NSNumber(floatLiteral: 100/Resolution!)
            }
            else {return nil}
        }
        else {return nil}
    }

}

extension VSMeasurementController: BufferDelegate {
    
    func didReceiveDataSignal(buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>) {
        
        if flagMeasured == 0 {
            
            flagMeasured = 1
            self.collectDataSignals(buffer: buffer)
        }
//        audioController!.stopIOUnit()
    }
}

extension VSMeasurementController: VibedataInputDelegate {
    
    func microphone(_ microphone: VibedataInput!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        /*
        let bufferSep = 4096
        let BinMultiplier1 = 1
        
        if flagMeasured == 0 {
            
            tryLoad! += 1
            
            if tryLoad == 1 {
                
                for i in 0..<bufferSep {
                    
                    acc_TWF![i] = buffer[0]![i] * Float(calibrationFactor) * Float(SensorMultiplier)
                    acc_TWF2![i] = buffer[1]![i] * Float(calibrationFactor) * Float(SensorMultiplier)
                }
            }
            
            for j in 2..<64 {
                
                if tryLoad == j {
                    
                    for i in Int(bufferSize) * (tryLoad! - 1)..<(bufferSep * tryLoad!) {
                        
                        acc_TWF![i] = buffer[0]![i-bufferSep*(tryLoad!-1)] * Float(calibrationFactor) * Float(SensorMultiplier)
                        acc_TWF2![i] = buffer[1]![i-bufferSep*(tryLoad!-1)] * Float(calibrationFactor) * Float(SensorMultiplier)
                    }
                }
            }
        }
        
        if tryLoad == BinMultiplier {
            
            tryLoad = 0
            
            DispatchQueue.main.async { [self] in
                
                if flagMeasured == 0 {
                    
                    flagMeasured = 1
                    
                    if microphone != nil {
                        
                        self.microphone!.stopFetchingAudio()
                        self.microphone = nil
                    }
                    
                    let acc_TWF_p = UnsafeMutablePointer<Float>.allocate(capacity: acc_TWF!.count)
                    acc_TWF_p.assign(from: acc_TWF!, count: acc_TWF!.count)
                    
                    let acc_TWF2_p = UnsafeMutablePointer<Float>.allocate(capacity: acc_TWF2!.count)
                    acc_TWF2_p.assign(from: acc_TWF2!, count: acc_TWF!.count)
                    
                    let fft1 = UnsafeMutablePointer<Float>.allocate(capacity: acc_TWF!.count)
                    let fft2 = UnsafeMutablePointer<Float>.allocate(capacity: acc_TWF!.count)
                    
                    let m_spectrumSize = 4096
                    integrationVar = 0
                    amplitudeUnits = 0
                    let velocityFactor = 61.4478989 as Float
                    Resolution = 11.71875
                    velRmsPeakInd = 0
                    let displacementFactor = 318.309998 as Float
                    let cutOffDisplacement = 0 as Int32
                    let flagWindowing = 0 as Int32
                    let flagChannelSelector = 2 as Int32
                    
                    VSFFTGenerator.toFFT_(from_DFTr: acc_TWF_p, andDFTi: acc_TWF2_p, inFFT1: fft1, andFFT2: fft2, forChannel: flagChannelSelector, spectrumSize: m_spectrumSize, integrationVar: Int32(integrationVar!), amplitudeUnits: Int32(amplitudeUnits!), velocityFactor: velocityFactor, resolution: Resolution!, displacementFactor: displacementFactor, cutOffDisplacement: cutOffDisplacement, velRmsPeakInd: velRmsPeakInd!, flagWindowing: flagWindowing)
                    
                    
                    self.plotAction()
                }
            }
        }*/
        
        let drawBuffers = buffer
        let drawBuffer_ptr = drawBuffers![0]
        acc_TWF = [] //acc_TWF
        acc_fft_rms = [] //vel_fft_rms
        vel_fft_rms = [] //acc_fft_rms
        flagChart = 1
        
        for drawBuffer_i in 0..<bufferSize {
//                if drawBuffers[drawBuffer_i] == nil { continue }
            
            let val = drawBuffers![0]![Int(drawBuffer_i)]
            acc_TWF!.append(val)
        }
        TWFChartView?.chart.updateData()
        
        let loadFromCSV = false
        
        if loadFromCSV {
            
            acc_fft_rms = self.loadTest_Acc_FFT_Rms()
            vel_fft_rms = self.loadTest_Vel_FFT_Rms()
            
        } else {
            
            let SR = 48000 as Int
            let coeff = 386.08858 as Float
            let BS = bufferSize //audioController?.bufferManagerInstance.bufferLength

            let spectra = fftTool?.acc_to_vel(acc_data: drawBuffer_ptr!, SR: SR, coeff: coeff, HPf: 2, BS: Int(BS))
            acc_fft_rms = spectra!.0
            vel_fft_rms = spectra!.1           
        }
        
        flagChart = 2
        FFTChartView?.chart.updateData()
    }
}

//
//  ViewController.swift
//  VibSim
//
//  Created by KS on 23/12/21.
//

import UIKit

var externSampleRate: Double?

class VSMainViewController: UIViewController {
    
    @IBOutlet var measurementBtn: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        externSampleRate = 44100

        self.title = "Vib Sim"
        measurementBtn?.titleLabel?.font = .boldSystemFont(ofSize: CGFloat(23))
        measurementBtn?.center = self.view.center
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    @IBAction func showMeasurementVC() {
        
        let measurementVc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MeasurementVC") as! VSMeasurementController
        measurementVc.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(measurementVc, animated: true)
    }
    
    @objc class func getExternSampleRate() -> Double {
        
        return externSampleRate!
    }
}


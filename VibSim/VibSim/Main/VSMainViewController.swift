//
//  ViewController.swift
//  VibSim
//
//  Created by KS on 23/12/21.
//

import UIKit

class VSMainViewController: UIViewController {
    
    
    @IBOutlet var measurementBtn: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Vib Sim"
        measurementBtn?.titleLabel?.font = .boldSystemFont(ofSize: CGFloat(23))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    @IBAction func showMeasurementVC() {
        
        let measurementVc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MeasurementVC") as! VSMeasurementController
        measurementVc.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(measurementVc, animated: true)
    }
}


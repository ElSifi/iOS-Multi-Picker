//
//  ViewController.swift
//  MultiPickerTest
//
//  Created by badi3 on 12/17/19.
//  Copyright © 2019 Badi3. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var resultLabel: UILabel!
    var preSelectedValues : [String] = []
    
    @IBAction func showOptionsAction(_ sender: Any) {
        let pickerData : [[String:String]] = [
            [
                "value":"en",
                "display":"English"
            ],
            [
                "value":"ar",
                "display":"العربية"
            ],
            [
                "value":"fr",
                "display":"le français"
            ]
        ]
        
        
        
        MultiPickerDialog().show(title: "Custom Title",doneButtonTitle:"Done Title", cancelButtonTitle:"Cancel Title" ,options: pickerData, selected:  preSelectedValues) {
            values -> Void in
            print("callBack \(values)")
            self.preSelectedValues = values.compactMap {return $0["value"]}
            
            let displayValues = values.compactMap {return $0["display"]}
            self.resultLabel.text = "Result = [\(displayValues.joined(separator: ", "))]"
        }
    }
    
}


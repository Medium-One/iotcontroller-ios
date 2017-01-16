//
//  gaugeSettingsPopup.swift
//
//  This file is part of Medium One IoT App for iOS
//  Copyright (c) 2016 Medium One.
//
//  The Medium One IoT App for iOS is free software: you can redistribute it
//  and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  The Medium One IoT App for iOS is distributed in the hope that it will be
//  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
//  Public License for more details.
//
//  You should have received a copy of the GNU General Public License along
//  with Medium One IoT App for iOS. If not, see
//  <http://www.gnu.org/licenses/>.
//
//  Popup for gauge widget settings

import UIKit

class gaugeSettingsPopup: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var auto: UISwitch!
    @IBOutlet weak var max: UITextField!
    @IBOutlet weak var min: UITextField!
    @IBOutlet weak var tag: UITextField!
    @IBOutlet weak var stream: UITextField!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var viewController: DetailViewController?
    var gaugeController: gaugeWidget?
    var index: Int?
    var timer: Timer?
    var value: Float?
    var tagLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get saved values
        stream.text = viewController?.widgetArray[index!]["stream"] as? String
        tag.text = viewController?.widgetArray[index!]["tag"] as? String
        min.text = String(describing: (viewController?.widgetArray[index!]["min"])!)
        max.text = String(describing: (viewController?.widgetArray[index!]["max"])!)
        auto.isOn = (viewController?.widgetArray[index!]["auto"] as? Bool)!
        
        // Screen dimensions
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Set frame and top constraints according to screen dimensions
        self.view.frame = CGRect(x: 0 , y: 0, width: screenWidth, height: screenHeight * 6)
        
        let newDistance = 50 + viewController!.tableView.contentOffset.y
        print(viewController!.tableView.contentOffset.y)
        topConstraint.constant = newDistance
        self.view.updateConstraints()
        
        // Disable background
        viewController!.tableView.isScrollEnabled = false
        
        // Enable return -> dismiss keyboard
        stream.delegate = self
        tag.delegate = self
        min.delegate = self
        max.delegate = self
        
        // Setup popup view
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.popupView.layer.cornerRadius = 5
        self.popupView.layer.shadowOpacity = 0.8
        self.popupView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.popupView.center = self.view.center
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Closes keyboard when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    // Saves all fields
    @IBAction func doneAction(_ sender: UIButton) {
        viewController?.widgetArray[index!].setObject(stream.text!, forKey: "stream" as NSCopying)
        viewController?.widgetArray[index!].setObject(tag.text!, forKey: "tag" as NSCopying)
        var minVal = Float(min.text!)
        if minVal != nil {
            viewController?.widgetArray[index!].setObject(minVal!, forKey: "min" as NSCopying)
        } else {
            minVal = Float((viewController?.widgetArray[index!]["min"])! as! String)
        }
        var maxVal = Float(max.text!)
        if maxVal != nil {
            viewController?.widgetArray[index!].setObject(maxVal!, forKey: "max" as NSCopying)
        } else {
            maxVal = Float((viewController?.widgetArray[index!]["max"])! as! String)
        }
        viewController?.widgetArray[index!].setObject(auto.isOn, forKey: "auto" as NSCopying)
        
        if !auto.isOn {
            gaugeController?.updateGauge(value!, auto: false, min: minVal!, max: maxVal!)
        }
        
        tagLabel?.text = tag.text
        
        self.removeAnimate()
    }
    
    // Invalidates timer and deletes widget
    @IBAction func deleteAction(_ sender: UIButton) {
        timer?.invalidate()
        timer = nil
        if index != nil {
            viewController?.deleteWidget(index!)
        }
        self.removeAnimate()
    }

    // Closes popup
    @IBAction func cancelAction(_ sender: UIButton) {
        self.removeAnimate()
    }
    
    // Shows popup
    func showInView(_ aView: UIView!, animated: Bool)
    {
        
        aView.addSubview(self.view)
        if animated
        {
            self.showAnimate()
        }
        viewDidLoad()
    }
    
    // Intro animation
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    // Exit animation
    func removeAnimate()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0;
            }, completion:{(finished : Bool)  in
                if (finished)
                {
                    self.view.removeFromSuperview()
                }
        });
        viewController?.tableView.isScrollEnabled = true
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }


}

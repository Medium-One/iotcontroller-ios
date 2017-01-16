//
//  settingsPopup.swift
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
//  Popup for when the settings icon is pressed for all widgets except JSON and gauge

import UIKit
import CoreLocation

class settingsPopup: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var tag: UITextField!
    @IBOutlet weak var stream: UITextField!
    @IBOutlet weak var widgetDetails: UITextView!
    @IBOutlet weak var widgetName: UILabel!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var viewController: DetailViewController?
    var index: Int?
    var name: String?
    var details: String?
    var manager: CLLocationManager?
    var gpsController: gpsWidget?
    var gpsSwitch: UISwitch?
    var timer: Timer?
    var tagLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set name and description
        widgetName.text = name
        widgetDetails.text = details
        
        // Get tag and stream if preveiously saved
        if index != nil {
            stream.text = viewController?.widgetArray[index!]["stream"] as? String
            tag.text = viewController?.widgetArray[index!]["tag"] as? String
        }
        
        // Screen dimensions
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Set frame and top constraint according to screen dimensions
        self.view.frame = CGRect(x: 0 , y: 0, width: screenWidth, height: screenHeight * 6)
        
        let newDistance = 50 + (viewController?.tableView.contentOffset.y)!
        topConstraint.constant = newDistance
        self.view.updateConstraints()
        
        // Disable background
        viewController?.tableView.isScrollEnabled = false
        
        // Enables return key -> dismiss keyboard
        tag.delegate = self
        stream.delegate = self
        
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
    
    // Hides keyboard when return button is pressed in a text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    // Save widget settings, activates GPS if needed
    @IBAction func doneAction(_ sender: UIButton) {
        if index != nil {
            viewController?.saveWidgetSettings(index!, stream: stream.text!, tag: tag.text!)
        }
        if name == "GPS" {
            gpsController?.gpsSwitched(gpsSwitch!) // Check if location manager needs to be turned back on
        }
        if name == "Log: Multi" {
            tagLabel?.text = (tag?.text)! + ":"
        } else {
            tagLabel?.text = tag?.text
        }
        self.removeAnimate()
    }
    
    // Deletes widget and invalidates timers
    @IBAction func deleteAction(_ sender: UIButton) {
        if name == "Log: Single" || name == "Log: Multi" || name == "Map" || name == "Gauge" { // Invalidate all timers
            timer?.invalidate()
            timer = nil
        }
        if index != nil {
            viewController?.deleteWidget(index!)
        }
        self.removeAnimate()
    }
    
    // Closes popup
    @IBAction func cancelAction(_ sender: UIButton) {
        tag.text = ""
        stream.text = ""
        self.removeAnimate()
        if name == "GPS" {
            gpsController?.gpsSwitched(gpsSwitch!) // Check if location manager needs to be turned back on
        }
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

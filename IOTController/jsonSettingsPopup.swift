
//
//  jsonSettingsPopup.swift
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
//  Popup for JSON widget settings

import UIKit

class jsonSettingsPopup: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var stream: UITextField!
    @IBOutlet weak var type: UISegmentedControl!
    @IBOutlet weak var key: UITextField!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var viewController: DetailViewController?
    var index: Int?
    var tagLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Gets saved values
        if index != nil {
            stream.text = viewController?.widgetArray[index!]["stream"] as? String
            key.text = viewController?.widgetArray[index!]["key"] as? String
            let typeIndex = (viewController?.widgetArray[index!]["valtype"] as? Int)!
            type.selectedSegmentIndex = typeIndex
        }
        
        // Screen dimensions
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Sets frame and top constraint according to screen dimensions
        self.view.frame = CGRect(x: 0 , y: 0, width: screenWidth, height: screenHeight * 6)
        
        let newDistance = 50 + (viewController?.tableView.contentOffset.y)!
        topConstraint.constant = newDistance
        self.view.updateConstraints()
        
        // Disables screen
        viewController?.tableView.isScrollEnabled = false
        
        // Enables return key -> dismiss keyboard
        stream.delegate = self
        key.delegate = self
        
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
    
    // Sets key, type, and stream for JSON object
    @IBAction func doneAction(_ sender: UIButton) {
        if index != nil {
            viewController?.widgetArray[index!].setObject(key.text!, forKey: "key" as NSCopying)
            viewController?.widgetArray[index!].setObject(type.selectedSegmentIndex, forKey: "valtype" as NSCopying)
            viewController?.widgetArray[index!].setObject(stream.text!, forKey: "stream" as NSCopying)
        }
        tagLabel?.text = (key?.text)! + ":"
        self.removeAnimate()
    }
    
    // Deletes widget
    @IBAction func deleteAction(_ sender: UIButton) {
        if index != nil {
            viewController?.deleteWidget(index!)
        }
        self.removeAnimate()
    }

    // Removes popup from screen
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

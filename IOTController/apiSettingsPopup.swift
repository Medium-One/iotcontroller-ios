//
//  apiSettingsPopup.swift
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
//  Popup for API settings including login information, profile name, and profile type

import UIKit

class apiSettingsPopup: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var type: UISegmentedControl!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var login: UITextField!
    @IBOutlet weak var key: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var viewController: DetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get saved values
        if let detail = viewController?.detailItem {
            name.text = detail.value(forKey: "name") as? String
            key.text = detail.value(forKey: "apiKey") as? String
            login.text = detail.value(forKey: "apiLogin") as? String
            password.text = detail.value(forKey: "apiPassword") as? String
            type.selectedSegmentIndex = detail.value(forKey: "sandbox") as! Int
        }
        
        // Screen dimensions
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Update frame and top constraint according to screen dimensions
        self.view.frame = CGRect(x: 0 , y: 0, width: screenWidth, height: screenHeight * 6)
        
        let newDistance = 50 + (viewController?.tableView.contentOffset.y)!
        topConstraint.constant = newDistance
        self.view.updateConstraints()
        
        // Disable background view
        viewController?.tableView.isScrollEnabled = false
        
        // Enables return -> dismiss keyboard
        name.delegate = self
        key.delegate = self
        login.delegate = self
        password.delegate = self
        
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
    
    // Closes keyboard when return button pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    // Saves values and logs in when done
    @IBAction func doneAction(_ sender: UIButton) {
        if let detail = viewController?.detailItem {
            detail.setValue(name.text!, forKey: "name")
            detail.setValue(login.text!, forKey: "apiLogin")
            detail.setValue(password.text!, forKey: "apiPassword")
            detail.setValue(key.text!, forKey: "apiKey")
            detail.setValue(type.selectedSegmentIndex, forKey: "sandbox")
        }
        viewController?.save()
        viewController?.navigationBar.title = name.text!
        viewController?.setURL(type.selectedSegmentIndex)
        viewController?.login()
        self.removeAnimate()
    }
    
    // Closes popup when cancelled
    @IBAction func cancelAction(_ sender: UIButton) {
        self.removeAnimate()
    }
    
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
    
    // Ending animation
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

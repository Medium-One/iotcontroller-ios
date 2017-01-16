//
//  addWidgetPopup.swift
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
//  Popup that allows user to choose which widget to add

import UIKit

class addWidgetPopup: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    // Widget types and descriptions
    var widgetArray = [["type":"GPS", "description":"Sends an event with your device GPS location every 5 seconds"], ["type":"Switch", "description":"Sends an event with a string \"on\" or \"off\""], ["type":"Slider", "description":"Sends an event with a number (1-100) upon a slider change"], ["type":"Gauge", "description":"Visualize data from a specific key"], ["type":"Notification", "description":"Prints the last event from a specific key"], ["type":"Log", "description":"Prints the last 10 events from a specific key"], ["type":"JSON", "description":"Sends an event in String, Number, or Boolean format"], ["type":"Map", "description":"Displays location from a specific key"]]
    
    var viewController: DetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Screen dimensions
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Update frame and top constraint according to screen dimensions
        self.view.frame = CGRect(x: 0 , y: 0, width: screenWidth, height: screenHeight * 6)
        
        let newDistance = 50 + (viewController?.tableView.contentOffset.y)!
        topConstraint.constant = newDistance
        self.view.updateConstraints()
        
        // Disable background
        viewController?.tableView.isScrollEnabled = false
        
        // Setup popup view
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.popupView.layer.cornerRadius = 5
        self.popupView.layer.shadowOpacity = 0.8
        self.popupView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        // Setup widget option table with custom cell widgetOption
        tableView.delegate = self
        tableView.dataSource = self
        let nib = UINib(nibName: "widgetOption", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "widgetOption")
    }
    
    
    // Allows cells to be at a custom height
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // Number of rows in table = number of widgets in array
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return widgetArray.count
    }
    
    // Creates a row for each widget type
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "widgetOption") as! widgetOption
        cell.type.text = widgetArray[indexPath.row]["type"]! as String
        cell.details.text = widgetArray[indexPath.row]["description"]! as String
        cell.icon.image = UIImage(imageLiteralResourceName: cell.type.text! + ".png")
        cell.button.tag = indexPath.row
        cell.button.addTarget(self, action: #selector(addWidgetPopup.buttonAction(_:)), for:UIControlEvents.touchUpInside)
        return cell
    }
    
    // Adds selected widget
    func buttonAction(_ object: UIButton) {
        switch object.tag {
        case 0:
            viewController?.addGPS()
        case 1:
            viewController?.addSwitch()
        case 2:
            viewController?.addSlider()
        case 3:
            viewController?.addGaugeWidget()
        case 4:
            viewController?.addWidget("singleWidget")
        case 5:
            viewController?.addWidget("multiWidget")
        case 6:
            viewController?.addJSONWidget()
        case 7:
            viewController?.addWidget("mapWidget")
        default:
            print("Not available yet")
        }
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
    
    // Cancel pressed
    @IBAction func closePopup(_ sender: AnyObject) {
        self.removeAnimate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

}

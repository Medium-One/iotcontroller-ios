//
//  gpsWidget.swift
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
//  GPS that updates every 5 seconds. Only one allowed per profile.

import UIKit
import CoreLocation

class gpsWidget: UITableViewCell, CLLocationManagerDelegate {

    @IBOutlet weak var switcher: UISwitch!
    @IBOutlet weak var tagLabel: UILabel!
    
    var viewController: DetailViewController?
    var index: Int?
    var setPopup = settingsPopup(nibName: "settingsPopup", bundle: nil)
    
    var isLocation = false
    var manager = CLLocationManager()
    var count = 0
    var location = ""
    var speed = 0.0
    var horizontalAccuracy = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup location manager
        self.manager.requestAlwaysAuthorization()
        self.manager.pausesLocationUpdatesAutomatically = false
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.allowsBackgroundLocationUpdates = true
        self.manager.delegate = self
        self.manager.pausesLocationUpdatesAutomatically = true
        
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(gpsWidget.checkGPS), userInfo: nil, repeats: false)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Sets timer to check GPS state
    override func prepareForReuse() {
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(gpsWidget.checkGPS), userInfo: nil, repeats: false)
    }
    
    // Checks to see if GPS is switched on in case location was turned off
    func checkGPS() {
        if switcher.isOn {
            gpsSwitched(switcher)
        }
    }
    
    // Creates settings popup when icon pressed
    @IBAction func gpsSettings(_ sender: UIButton) {
        if index == nil {
            return
        }
        
        setPopup.viewController = viewController
        setPopup.manager = manager
        setPopup.gpsController = self
        setPopup.gpsSwitch = switcher
        setPopup.name = "GPS"
        setPopup.details = "Sends an event with your device GPS location every 5 seconds"
        setPopup.index = index
        setPopup.tagLabel = self.tagLabel
        setPopup.showInView(self.superview, animated: true)
    }
    
    // Creates warning message
       
    // Starts sending GPS information when switch is on
     @IBAction func gpsSwitched(_ sender: UISwitch) {
        if index == nil {
            return
        }
        
        viewController?.widgetArray[index!]["on"] = sender.isOn
        let stream = (viewController?.widgetArray[index!]["stream"]) as? String
        let tag = (viewController?.widgetArray[index!]["tag"]) as? String
        
        // Check for errors
        if !(viewController?.active)! {
            sender.isOn = false
            viewController?.widgetWarning("GPS", reason: "login")
            return
        }
        if stream! == "" || stream!.contains(" ") {
            sender.isOn = false
            viewController?.widgetWarning("GPS", reason: "stream")
            return
        }
        if tag! == "" || tag!.contains(" ") {
            sender.isOn = false
            viewController?.widgetWarning("GPS", reason: "tag")
            return
        }
        
        self.isLocation = sender.isOn
    
        if (self.isLocation) {
            self.manager.startUpdatingLocation()
        } else {
            self.manager.stopUpdatingLocation()
        }
    }
    
     // Checks GPS Location if switch is on
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     
        var bgTask = UIBackgroundTaskInvalid
     
        if UIApplication.shared.applicationState == UIApplicationState.background {
            bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
                UIApplication.shared.endBackgroundTask(bgTask)
            })
        }
     
        if (count % 5 == 0 && self.isLocation) {
            let lastLocation = locations.last
            speed = lastLocation!.speed
            location = "\(lastLocation!.coordinate.latitude) \(lastLocation!.coordinate.longitude) \(lastLocation!.altitude)"
            horizontalAccuracy = lastLocation!.horizontalAccuracy
     
            sendGPSEvent()
        }
     
        count += 1 // Each count = 1 second
     
        if (bgTask != UIBackgroundTaskInvalid){
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid;
        }
     
    }

     // Function for sending GPS Events
     func sendGPSEvent() {
        if index == nil {
            return
        }
        
        let stream = (viewController?.widgetArray[index!]["stream"]) as? String
        let tag = (viewController?.widgetArray[index!]["tag"]) as? String
        
        if !(viewController?.active)! || stream == nil || tag == nil || stream! == "" || tag! == "" || stream!.contains(" ") || tag!.contains(" ") {
            return
        }
        
        var data = [String: Any]()
        var tagArray = tag!.components(separatedBy: ".")
        
        data = [
            "device_location":location,
            "device_speed":speed,
            "horizontal_accuracy":horizontalAccuracy]
        
        // For nested tags
        let arrayLength = tagArray.count
        if arrayLength > 1 {
            for index in stride(from: tagArray.count - 1, to: 0, by: -1) {
                data = [tagArray[index]:data as Any]
            }
        }
        
        data = [tagArray[0]:data as AnyObject]
        
        let json = ["event_data": data] as NSDictionary
        let url = (viewController?.baseUrl)! + "events/" + stream! + "/"
        viewController?.postJSON(url, jsonObj: json) { (data, error) -> Void in
            print(data)
        }
     }
}

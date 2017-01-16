//
//  DetailViewController.swift
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
//  Displays and saves all profile data.

import UIKit
import CoreData
import CoreLocation
import Foundation
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import MapKit

class DetailViewController: UITableViewController, UITextFieldDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    var session:URLSession!
    var baseUrl: String!
    var setPopup = apiSettingsPopup(nibName: "apiSettingsPopup", bundle: nil)
    var savedPopup = savedView(nibName: "savedView", bundle: nil)
    var widgetArray = [NSMutableDictionary]()
    var data = [NSManagedObject]()
    
    var gpsWidgetVar: gpsWidget?
    var singleArray = [singleEventWidget]()
    var multiArray = [multiEventWidget]()
    var mapArray = [mapWidget]()
    var gaugeArray = [gaugeWidget]()
    
    var gpsPresent = false
    
    var active = false

    // Data model variable
    var detailItem: AnyObject? {
        didSet {
        }
    }
    
    // Hides keyboard when return button is pressed in a text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // If login info is saved, login. Else, prompt user.
    func checkLogin(_ login: String, password: String, key: String, sandbox: Int) {
        if login != "" && password != "" && key != "" {
            setURL(sandbox)
            self.login()
        } else {
            NSLog("No login found!")
            self.settingsPressed(self.settingsButton)
        }
    }
    
    // Sets name at top of screen
    func setName(_ name: String) {
        navigationBar.title = name
    }
    
    // Invalidates timers when leaving view
    override func viewWillDisappear(_ animated: Bool) {
        invalidateTimers()
    }
    
    // Turns off all active timers to prevent communication outside profile
    func invalidateTimers() {
        gpsWidgetVar?.manager.stopUpdatingLocation()
        if singleArray.count != 0 {
            for index in 0...singleArray.count - 1 {
                singleArray[index].timer?.invalidate()
            }
        }
        if multiArray.count != 0 {
            for index in 0...multiArray.count - 1 {
                multiArray[index].timer?.invalidate()
            }
        }
        if mapArray.count != 0 {
            for index in 0...mapArray.count - 1 {
                mapArray[index].timer?.invalidate()
            }
        }
        if gaugeArray.count != 0 {
            for index in 0...gaugeArray.count - 1 {
                gaugeArray[index].timer?.invalidate()
            }
        }
    }
    
    // Disables back swipe
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = URLSession.shared
        
        self.navigationController?.navigationController?.interactivePopGestureRecognizer!.delegate = self
        
        // Use saved information to login and set name
        if let detail = self.detailItem {
            checkLogin(((detail.value(forKey: "apiLogin") as AnyObject).description)!, password: ((detail.value(forKey: "apiPassword") as AnyObject).description)!, key: ((detail.value(forKey: "apiKey") as AnyObject).description)!, sandbox: (detail.value(forKey: "sandbox") as! Int))
            setName(((detail.value(forKey: "name") as AnyObject).description)!)
        }

        // Add custom classes to table view
        let nib1 = UINib(nibName: "newWidget", bundle: nil)
        let nib2 = UINib(nibName: "gpsWidget", bundle: nil)
        let nib3 = UINib(nibName: "switchWidget", bundle: nil)
        let nib4 = UINib(nibName: "sliderWidget", bundle: nil)
        let nib5 = UINib(nibName: "gaugeWidget", bundle: nil)
        let nib6 = UINib(nibName: "singleEventWidget", bundle: nil)
        let nib7 = UINib(nibName: "multiEventWidget", bundle: nil)
        let nib8 = UINib(nibName: "jsonWidget", bundle: nil)
        let nib9 = UINib(nibName: "mapWidget", bundle: nil)
        
        tableView.register(nib1, forCellReuseIdentifier: "newWidget")
        tableView.register(nib2, forCellReuseIdentifier: "gpsWidget")
        tableView.register(nib3, forCellReuseIdentifier: "switchWidget")
        tableView.register(nib4, forCellReuseIdentifier: "sliderWidget")
        tableView.register(nib5, forCellReuseIdentifier: "gaugeWidget")
        tableView.register(nib6, forCellReuseIdentifier: "singleEventWidget")
        tableView.register(nib7, forCellReuseIdentifier: "multiEventWidget")
        tableView.register(nib8, forCellReuseIdentifier: "jsonWidget")
        tableView.register(nib9, forCellReuseIdentifier: "mapWidget")
        
        self.loadArray()
        self.tableView.tableFooterView = UIView() // Removes extra rows

        // Makes keyboards close when screen tapped away
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DetailViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    
        // Checks for notifications of app closing or opening
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResign), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResign), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillReturn), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }

    // Saves data and pauses timers when exiting app
    func applicationWillResign() {
        save()
        invalidateTimers()
    }
    
    // Reloads data when entering app
    func applicationWillReturn() {
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Loads widget array data into table view
    func loadArray() {
        if let detail = self.detailItem {
            let widgetStr = (detail.value(forKey: "widgets") as AnyObject).description
            let widgetStrArray = widgetStr!.components(separatedBy: "\n") // Array of widgets as Strings
            if String(widgetStrArray[0]) != "" {
                for index in 0...(widgetStrArray.count - 1) {
                    widgetArray.append(NSMutableDictionary(dictionary: self.convertStringToDictionary(widgetStrArray[index])!)) // string array -> dictionary array
                }
            }
        }
    }
    
    // Dismisses keyboard when called
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Number of rows = number of objects in array
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return widgetArray.count
    }

    // Creates each widget row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = widgetArray[indexPath.row]["type"] as! String
        switch type {
        case "gpsWidget":
            let cell = tableView.dequeueReusableCell(withIdentifier: "gpsWidget", for: indexPath) as! gpsWidget
            cell.viewController = self
            cell.index = indexPath.row
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.tagLabel.text = widgetArray[indexPath.row]["tag"] as? String
            gpsPresent = true // Only one GPS widget allowed
            gpsWidgetVar = cell // For timer tracking
            return cell
        case "switchWidget":
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchWidget", for: indexPath) as! switchWidget
            cell.viewController = self
            cell.switcher.isOn = widgetArray[indexPath.row]["on"] as! Bool
            cell.index = indexPath.row
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.tagLabel.text = widgetArray[indexPath.row]["tag"] as? String
            return cell
        case "sliderWidget":
            let cell = tableView.dequeueReusableCell(withIdentifier: "sliderWidget", for: indexPath) as! sliderWidget
            cell.viewController = self
            cell.index = indexPath.row
            let value = widgetArray[indexPath.row]["value"]
            cell.sliderLabel.text = String(format: "%d", Int(value! as! NSNumber))
            cell.slider.value = value as! Float
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.tagLabel.text = widgetArray[indexPath.row]["tag"] as? String
            return cell
        case "gaugeWidget":
            let cell = tableView.dequeueReusableCell(withIdentifier: "gaugeWidget", for: indexPath) as! gaugeWidget
            cell.viewController = self
            cell.index = indexPath.row
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.tagLabel.text = widgetArray[indexPath.row]["tag"] as? String
            if widgetArray[indexPath.row]["new"] as! Bool { // To prevent refreshes from changing data
                let min = widgetArray[indexPath.row]["min"]
                let max = widgetArray[indexPath.row]["max"]
                cell.gaugemin = min as! Float
                cell.gaugemax = max as! Float
                cell.redrawGauge(20)
            }
            gaugeArray.append(cell)
            return cell
        case "singleWidget": 
            let cell = tableView.dequeueReusableCell(withIdentifier: "singleEventWidget", for: indexPath) as! singleEventWidget
            cell.viewController = self
            cell.index = indexPath.row
            if widgetArray[indexPath.row]["new"] as! Bool { // To prevent refreshes from changing data
                cell.valueLabel.text = "No Events Available"
                cell.dateLabel.text = ""
            }
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            singleArray.append(cell)
            return cell
        case "multiWidget":
            let cell = tableView.dequeueReusableCell(withIdentifier: "multiEventWidget", for: indexPath) as! multiEventWidget
            cell.viewController = self
            cell.index = indexPath.row
            if widgetArray[indexPath.row]["new"] as! Bool { // To prevent refreshes from changing data
                cell.log.text = "No Events Available"
            }
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.tagLabel.text = (widgetArray[indexPath.row]["tag"] as? String)!
            multiArray.append(cell)
            return cell
        case "jsonWidget":
            let cell = tableView.dequeueReusableCell(withIdentifier: "jsonWidget", for: indexPath) as! jsonWidget
            cell.viewController = self
            cell.index = indexPath.row
            if widgetArray[indexPath.row]["new"] as! Bool { // To prevent refreshes from changing data
                cell.value.text = ""
            }
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.tagLabel.text = widgetArray[indexPath.row]["key"] as? String
            return cell
        case "mapWidget":
            let cell = tableView.dequeueReusableCell(withIdentifier: "mapWidget", for: indexPath) as! mapWidget
            cell.viewController = self
            cell.index = indexPath.row
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.tagLabel.text = widgetArray[indexPath.row]["tag"] as? String
            mapArray.append(cell)
            return cell
        default: // "Add widget"
            let cell = tableView.dequeueReusableCell(withIdentifier: "newWidget", for: indexPath) as! NewWidget
            cell.viewController = self
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        }
    }
    
    // Customize row height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if widgetArray[indexPath.row]["type"] == nil {
            return 80
        }
        switch widgetArray[indexPath.row]["type"] as! String {
        case "gpsWidget", "switchWidget":
            return 75
        case "sliderWidget":
            return 80
        case "gaugeWidget":
            return 150
        case "singleWidget":
            return 70
        case "multiWidget":
            return 300
        case "jsonWidget":
            return 120
        case "mapWidget":
            return 305
        default:
            return 80
        }

    }
    
    // Generic function to add map, log, and notification widgets
    func addWidget(_ type: String){
        widgetArray.insert(["type":type, "stream": "", "tag": "", "new": true], at: widgetArray.count - 1)
        let path = IndexPath(row: widgetArray.count - 2, section: 0)
        tableView.insertRows(at: [path], with: .automatic)
        if widgetArray.count >= 11 {
            deleteWidget(widgetArray.count - 1) // Removes ability to add new widgets
        }
    }
    
    // Adds JSON widget
    func addJSONWidget() {
        widgetArray.insert(["type":"jsonWidget", "stream": "", "key": "", "value":"", "valtype":0, "new": true], at: widgetArray.count - 1)
        let path = IndexPath(row: widgetArray.count - 2, section: 0)
        tableView.insertRows(at: [path], with: .automatic)
        if widgetArray.count >= 11 {
            deleteWidget(widgetArray.count - 1) // Removes ability to add new widgets
        }
    }

    // Adds gauge widget
    func addGaugeWidget() {
        widgetArray.insert(["type":"gaugeWidget", "stream":"", "tag":"", "min":Float(0), "max":Float(100), "auto":false, "new":true], at: widgetArray.count - 1)
        let path = IndexPath(row: widgetArray.count - 2, section: 0)
        tableView.insertRows(at: [path], with: .automatic)
        if widgetArray.count >= 11 {
            deleteWidget(widgetArray.count - 1) // Removes ability to add new widgets
        }
    }
    
    // Adds GPS widget above Add Widget button
    func addGPS() {
        if !gpsPresent { // Only one GPS Widget per Profile
            widgetArray.insert(["type":"gpsWidget", "stream": "", "tag": ""], at: widgetArray.count - 1)
            let path = IndexPath(row: widgetArray.count - 2, section: 0)
            tableView.insertRows(at: [path], with: .automatic)
            if widgetArray.count >= 11 {
                deleteWidget(widgetArray.count - 1) // Removes ability to add new widgets
            }
        }
    }
    
    // Adds switch widget
    func addSwitch() {
        widgetArray.insert(["type":"switchWidget", "stream": "", "tag": "", "on": false], at: widgetArray.count - 1)
        let path = IndexPath(row: widgetArray.count - 2, section: 0)
        tableView.insertRows(at: [path], with: .automatic)
        if widgetArray.count >= 11 {
            deleteWidget(widgetArray.count - 1) // Removes ability to add new widgets
        }
    }
    
    // Adds slider widget
    func addSlider() {
        widgetArray.insert(["type": "sliderWidget", "stream": "", "tag": "", "value": Float(20)], at: widgetArray.count - 1)
        let path = IndexPath(row: widgetArray.count - 2, section: 0)
        tableView.insertRows(at: [path], with: .automatic)
        if widgetArray.count >= 11 {
            deleteWidget(widgetArray.count - 1) // Removes ability to add new widgets
        }
    }

    // Saves widget stream and tag
    func saveWidgetSettings(_ index: Int, stream: String, tag: String) {
        widgetArray[index].setObject(stream, forKey: "stream" as NSCopying)
        widgetArray[index].setObject(tag, forKey: "tag" as NSCopying)
    }
    
    // Deletes widget at given index
    func deleteWidget(_ index: Int) {
        if widgetArray[index]["type"] as! String == "gpsWidget" {
            gpsPresent = false // Allows a GPS widget to be added again
            gpsWidgetVar = nil // Removes timer tracking from GPS widget
        }
        
        widgetArray.remove(at: index)
        var path = IndexPath(row: index, section: 0)
        invalidateTimers() // Invalidates all timers
        tableView.deleteRows(at: [path], with: .automatic)
        
        if widgetArray.count < 10 && widgetArray[widgetArray.count-1]["type"] as! String != "newWidget" { //Allows user to add widget again if moving down from max number of widgets
            widgetArray.append(["type":"newWidget"])
            path = IndexPath(row: widgetArray.count - 1, section: 0)
            tableView.insertRows(at: [path], with: .automatic)
        }
        
        tableView.reloadData()
    }
    
    // Saves current widgets by converting array to String and saving it in data model
    @IBAction func saveWidgets(_ sender: UIBarButtonItem) {
        if let detail = self.detailItem {
            var stringArray = [String]()
            for index in 0...widgetArray.count - 1 {
                stringArray.append(stringifyJSON(widgetArray[index])) // dictionary array -> string array
            }
            let arrayString = stringArray.joined(separator: "\n") // string array -> string
            detail.setValue(arrayString, forKey: "widgets")
            self.save()
        }
        savedPopup.viewController = self
        savedPopup.showInView(self.view, animated: true)
    }

    // Function for API Settings button, creates popup
    @IBAction func settingsPressed(_ sender: UIBarButtonItem) {
        setPopup.viewController = self
        setPopup.showInView(self.view, animated: true)
    }
    
    // Sets base URL for getting and receiving data
    func setURL(_ option: Int) {
        switch option {
        case 1:
             self.baseUrl = "https://api.mediumone.com/v2/"
        case 2:
            self.baseUrl = "https://api-renesas-na-sandbox.mediumone.com/v2/"
        default:
            self.baseUrl = "https://api-sandbox.mediumone.com/v2/"
        }
    }
    
    // Logs into Medium One using API settings, saved API settings are not nil
    func login() {
        
        // Initialize values
        var login = ["":""]
        let url = self.baseUrl + "login/"
        if let detail = self.detailItem {
            login = ["login_id":detail.value(forKey: "apiLogin")! as! String, "password":detail.value(forKey: "apiPassword")! as! String, "api_key":detail.value(forKey: "apiKey")! as! String]
        }
        
        self.postJSON(url, jsonObj: login as AnyObject) { (data, error) -> Void in
            print(data)
            
            if data == "true" { // Logged in
                // Change Settings button to show successful login
                DispatchQueue.main.async(execute: {
                    self.settingsButton.title = "API Login ✓"
                    self.settingsButton.tintColor = UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1)
                    })
                self.active = true
                self.sendToken() // For push notifications
            } else {
                // Change Settings button to show failed login
                DispatchQueue.main.async(execute: {
                    self.settingsButton.title = "API Login ✗"
                    self.settingsButton.tintColor = UIColor.red
                })
                
                // Determine error type
                var error = "Invalid Login ID"
                if (data.contains("exceed")) {
                    error = "Exceeded Bad Login Count"
                } else if (data.contains("password")) {
                    error = "Invalid Password"
                } else if (data.contains("api")) {
                    error = "Invalid API Key"
                }
                
                self.loginError(error)
                
            }
        }
    }
    
    func loginError(_ error: String) {
        // Create alert controller
        let alertController = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertControllerStyle.alert)
        alertController.isModalInPopover = true
        
        let tryAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            
            self.settingsPressed(self.settingsButton)
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            alert -> Void in
            
        })
        
        
        alertController.addAction(tryAction)
        alertController.addAction(cancelAction)
        
        DispatchQueue.main.async(execute: {
            self.present(alertController, animated: true, completion: nil)
        })

    }
    
    // Warns user of improper use of widgets
    func widgetWarning(_ widget: String, reason: String) {
        // Create alert controller
        let alertController = UIAlertController(title: "Warning", message: "Attempting to use " + widget + " without valid " + reason + ".", preferredStyle: UIAlertControllerStyle.alert)
        alertController.isModalInPopover = true
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            
        })
        
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    
    // Sends token to raw stream
    func sendToken() {
        if let token = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(token)")
        
            let data = ["FCM_token":token]
            let json = ["event_data":data
                ] as NSDictionary
            let url = self.baseUrl + "events/raw/"
    
            self.postJSON(url, jsonObj: json) { (json, error) -> Void in
                print(json)
            }
        }
    }
    
    // Converts a string to a dictionary
    func convertStringToDictionary(_ text: String) -> [String:AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    // Saves data model
    func save() {
        let appDelegate =
            UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    // Sends JSON to Medium One
    func postJSON(_ url: String,
                  jsonObj: AnyObject,
                  callback: @escaping (String, String?) -> Void) {
        if url.contains(" ") {
            return
        }
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/json",
                         forHTTPHeaderField: "Content-Type")
        let jsonString = stringifyJSON(jsonObj)
        let data: Data = jsonString.data(
            using: String.Encoding.utf8)!
        request.httpBody = data
        sendRequest(request,callback: callback)
    }
    
    // Turns JSON into string
    func stringifyJSON(_ value: AnyObject,prettyPrinted:Bool = false) -> String{
        
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            } catch {
                print("error")
            }
        }
        return ""
    }
    
    // Sends data request
    func sendRequest(_ request: URLRequest,
                     callback: @escaping (String, String?) -> Void) {
        let task = session.dataTask(with: request, completionHandler: {(data, response,
            error) -> Void in
            if error != nil {
                callback("", (error!.localizedDescription) as String)
            } else {
                callback(
                    NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as! String,
                    nil
                )
            }
        }) 
        task.resume()
    }
}

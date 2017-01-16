//
//  jsonWidget.swift
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
//  Allows user to send a string, boolean, or number value to a specified stream and tag

import UIKit

class jsonWidget: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var logOutput: UITextView!
    @IBOutlet weak var value: UITextField!
    @IBOutlet weak var tagLabel: UILabel!
    
    var viewController: DetailViewController?
    var index: Int?
    var setPopup = jsonSettingsPopup(nibName: "jsonSettingsPopup", bundle: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        value.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Creates settings popup when icon is pressed
    @IBAction func jsonSettings(_ sender: UIButton) {
        if index == nil {
            return
        }
        
        viewController?.widgetArray[index!]["new"] = false
        setPopup.viewController = viewController
        setPopup.index = index
        setPopup.tagLabel = tagLabel
        setPopup.showInView(self.superview, animated: true)
    }

    // Dismisses keyboard when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
    
    // Popup created when invalid value for type is sent
    func invalidValue() {
        // Create alert controller
        let alertController = UIAlertController(title: "Error", message: "Attempting to send invalid value", preferredStyle: UIAlertControllerStyle.alert)
        alertController.isModalInPopover = true
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            
        })
        
        alertController.addAction(okAction)
        
        viewController?.present(alertController, animated: true, completion: nil)
    }
    
    // Sends JSON when send button is pressed
    @IBAction func sendJSON(_ sender: UIButton) {
        self.endEditing(true)
        if index == nil {
            return
        }
        
        let valIndex = viewController?.widgetArray[index!]["valtype"] as! Int
        let key = viewController?.widgetArray[index!]["key"] as! String
        let stream = viewController?.widgetArray[index!]["stream"] as! String
        
        if !(viewController?.active)! {
            viewController?.widgetWarning("JSON", reason: "login")
            return
        }
        if stream == "" || stream.contains(" ") {
            viewController?.widgetWarning("JSON", reason: "stream")
            return
        }
        if key == "" || key.contains(" ") {
            viewController?.widgetWarning("JSON", reason: "key")
            return
        }
        
        var data = [String: Any]()
        var valueObj: AnyObject!
        var keyArray = key.components(separatedBy: ".")
        
        // Set value to correct type
        valueObj = value.text! as AnyObject! // Sends value as string
        
        if (valIndex == 1) {
            if (self.value.text?.caseInsensitiveCompare("true") == ComparisonResult.orderedSame) || (self.value.text?.caseInsensitiveCompare("false") == ComparisonResult.orderedSame) {
                valueObj = NSString(string: self.value.text!).boolValue as AnyObject! // Sends value as bool
            } else {
                invalidValue()
                return
            }
        } else if (valIndex == 2) {
            let valueDouble = Double(value.text!)
            if valueDouble != nil {
                valueObj = NSString(string: self.value.text!).doubleValue as AnyObject! // Sends value as double
            } else {
                invalidValue()
                return
            }
        }
        
        let arrayLength = keyArray.count
        data = [keyArray[arrayLength - 1]: valueObj]
        
        // For nested tags
        if arrayLength > 1 {
            for index in stride(from: keyArray.count - 2, to: -1, by: -1) {
                let ind = keyArray[index]
                data = [ind:data as AnyObject]
            }
        }
        
        let json = ["event_data":data] as NSDictionary
        
        let url = (viewController?.baseUrl)! + "events/" + stream + "/"
        
        viewController?.postJSON(url, jsonObj: json) { (json, error) -> Void in
            DispatchQueue.main.async(execute: {
                self.logOutput.text = json as String
                print (json as String)
            })
            
        }
    }
}

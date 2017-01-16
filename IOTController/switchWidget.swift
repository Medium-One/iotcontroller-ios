//
//  switchWidget.swift
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
//  Switch widget that sends "off" or "on" to specified tag and stream

import UIKit

class switchWidget: UITableViewCell {
    
    @IBOutlet weak var switcher: UISwitch!
    @IBOutlet weak var tagLabel: UILabel!
    
    var viewController: DetailViewController?
    var index: Int?
    var setPopup = settingsPopup(nibName: "settingsPopup", bundle: nil)
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Creates settings popup when icon pressed
    @IBAction func switchSettings(_ sender: UIButton) {
        if index == nil {
            return
        }
        
        setPopup.viewController = viewController
        setPopup.name = "Switch"
        setPopup.details = "Sends an event with a string \"on\" or \"off\""
        setPopup.index = index
        setPopup.tagLabel = tagLabel
        setPopup.showInView(self.superview, animated: true)
    }
    
    
    // Function for switch changing value
    @IBAction func switchPressed(_ sender: AnyObject) {
        if index == nil {
            return
        }
        
        viewController?.widgetArray[index!]["on"] = sender.isOn
        let stream = (viewController?.widgetArray[index!]["stream"]) as? String
        let tag = (viewController?.widgetArray[index!]["tag"]) as? String
        
        // Check for errors
        if !(viewController?.active)! {
            switcher.isOn = false
            viewController?.widgetWarning("switch", reason: "login")
            return
        }
        if stream! == "" || stream!.contains(" ") {
            switcher.isOn = false
            viewController?.widgetWarning("switch", reason: "stream")
            return
        }
        if tag! == "" || tag!.contains(" ") {
            switcher.isOn = false
            viewController?.widgetWarning("switch", reason: "tag")
            return
        }
        
        let value = sender.isOn! ? "on" : "off"
        
        var data = [String: Any]()
        var tagArray = tag!.components(separatedBy: ".")
        let arrayLength = tagArray.count
        data = [tagArray[arrayLength - 1]: value]
        
        // For nested tags
        if arrayLength > 1 {
            for index in stride(from: tagArray.count - 2, to: -1, by: -1) {
                let ind = tagArray[index]
                data = [ind:data as AnyObject]
            }
        }

        let json = ["event_data":data] as NSDictionary
        let url = (viewController?.baseUrl)! + "events/" + stream! + "/"
            
        viewController?.postJSON(url, jsonObj: json) { (data, error) -> Void in
            print(data)
    
        }
    }
}

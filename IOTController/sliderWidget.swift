//
//  sliderWidget.swift
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
//  Slider widget which sends values 1-100 to tag

import UIKit

class sliderWidget: UITableViewCell {

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var sliderLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    
    var viewController: DetailViewController?
    var index: Int?
    var setPopup = settingsPopup(nibName: "settingsPopup", bundle: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(sliderWidget.handleTap(_:)))
        self.slider.addGestureRecognizer(tap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Creates settings popup when icon is pressed
    @IBAction func sliderSettings(_ sender: UIButton) {
        if index == nil {
            return
        }
        
        setPopup.viewController = viewController
        setPopup.name = "Slider"
        setPopup.details = "Sends an event with a number (1-100) upon a slider change"
        setPopup.index = index
        setPopup.tagLabel = tagLabel
        setPopup.showInView(self.superview, animated: true)
    }
    
    // For small changes in slider
    @IBAction func handleTap(_ recognizer:UITapGestureRecognizer) {
        let slider = (recognizer.view as! UISlider)
        if slider.isHighlighted {
            self.slider.value = slider.value
        }
        self.sendSliderValue(slider)
    }
    
    // Changes slider label according to value
    @IBAction func sliderChanged(_ sender: UISlider) {
        let value = sender.value
        sliderLabel.text = String(format: "%d", Int(value)) // Sets value label whether or not it sends
    }
    
    // Resets slider settings in case of error
    func resetSettings() {
        // Reset widget settings
        let prevVal = viewController?.widgetArray[index!]["value"]
        slider.value = Float(prevVal as! Int)
        sliderLabel.text = String(format: "%d", prevVal as! Int)
    }

    // Sends slider value after user lets go of slider
    @IBAction func sendSliderValue(_ sender: UISlider) {
        if index == nil {
            return
        }
        
        let stream = (viewController?.widgetArray[index!]["stream"]) as? String
        let tag = (viewController?.widgetArray[index!]["tag"]) as? String
        
        // Check for errors
        if !(viewController?.active)! {
            resetSettings()
            viewController?.widgetWarning("slider", reason: "login")
            return
        }
        if stream! == "" || stream!.contains(" ") {
            resetSettings()
            viewController?.widgetWarning("slider", reason: "stream")
            return
        }
        if tag! == "" || tag!.contains(" ") {
            resetSettings()
            viewController?.widgetWarning("slider", reason: "tag")
            return
        }
        
        viewController?.widgetArray[index!]["value"] = slider.value
        
        var data = [String: AnyObject]()
        var tagArray = tag!.components(separatedBy: ".")
        let arrayLength = tagArray.count
        let origVal = Int(sender.value) as AnyObject!
        data = [tagArray[arrayLength - 1]: origVal!]
        
        // For nested tags
        if arrayLength > 1 {
            for index in stride(from: tagArray.count - 2, to: -1, by: -1) {
                data = [tagArray[index]:data as AnyObject]
            }
        }
        
        let json = ["event_data":data] as NSDictionary
        let url = (viewController?.baseUrl)! + "events/" + stream! + "/"
        
        viewController?.postJSON(url, jsonObj: json) { (data, error) -> Void in
            print(data)
        }
    }
}

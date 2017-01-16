//
//  gaugeWidget.swift
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
//  Gauge widget with customizable value and min and max
//  Auto option will automatically control the min and max, with the first value being in the middle

import UIKit
import MSSimpleGauge

class gaugeWidget: UITableViewCell {

    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var gaugeView: UIView!
    @IBOutlet weak var gaugeContainer: UIView!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    
    var viewController: DetailViewController?
    var index: Int?
    var timer: Timer?
    var setPopup = gaugeSettingsPopup(nibName: "gaugeSettingsPopup", bundle: nil)
    
    var gauge: MSSimpleGauge!
    var gaugemin: Float!
    var gaugemax: Float!
    var firstVal = true
    
    // Sets timers to check if gauge values are updated
    override func awakeFromNib() {
        super.awakeFromNib()
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(gaugeWidget.checkGauge), userInfo: nil, repeats: false) //one time check in case of table refresh
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(gaugeWidget.getEvents), userInfo: nil, repeats: true) //checks for new data every 2 seconds
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Redraws gauge if gauge is nil
    func checkGauge() {
        if gauge == nil {
            gaugemin = Float(minLabel.text! as String)
            gaugemax = Float(maxLabel.text! as String)
            redrawGauge(Float(value.text! as String)!)
        }
    }
    
    // Creates new timer when cell is reused - either when readded or refreshed
    override func prepareForReuse() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(gaugeWidget.getEvents), userInfo: nil, repeats: true)
    }
    
    // Creates settings popup when icon is pressed
    @IBAction func gaugeSettings(_ sender: UIButton) {
        if index == nil {
            return
        }
        
        setPopup.viewController = viewController
        setPopup.index = index
        setPopup.timer = timer
        setPopup.gaugeController = self
        setPopup.value = Float(value.text!)
        setPopup.tagLabel = tagLabel
        setPopup.showInView(self.superview, animated: true)
    }
    
     // Redraws gauge and value on the screen
    func redrawGauge(_ value: Float) {
        if index == nil {
            return
        }
        
        viewController?.widgetArray[index!]["new"] = false
        
        // Clear subview
        for view in (self.gaugeContainer.subviews) { //Gauge has own tag
            if view.tag == 99 {
                view.removeFromSuperview()
            }
        }
        
        // Set gauge drawing settings
        gauge = MSSimpleGauge(frame: CGRect(x: 0, y: 0, width: 153, height: 97.5))
        gauge.tag = 99
        gauge.fillArcFillColor = UIColor(
            red: 93/255,
            green: 188/255,
            blue: 210/255,
            alpha: CGFloat(1.0)
        )
        gauge.backgroundColor = UIColor.clear
        gauge.backgroundArcFillColor = UIColor.lightGray
        gauge.backgroundGradient = nil
        gauge.arcThickness = 0.1
        gauge.startAngle = 0
        gauge.endAngle = 180
        
        // Determine min and max
        if (gaugemin < 0) {
            gauge.minValue = gaugemin - gaugemin // Makes min = 0 for gauge and shifts everything else by min accordingly bc gauge cannot handle negative values
            gauge.maxValue = gaugemax - gaugemin
            gauge.value = value - gaugemin
        } else {
            gauge.minValue = gaugemin
            gauge.maxValue = gaugemax
            gauge.value = value
        }
        
        // Set labels
        minLabel.text = String(gaugemin)
        maxLabel.text = String(gaugemax)
        
        self.value.text = String(value)
        
        // Add back to subview
        self.gaugeContainer.addSubview(gauge)
    }

    // Function for accessing changes to gauge tag - checked every 2 seconds
    func getEvents() {
        
        if index == nil {
            return
        }
        
        // Get previous values
        let stream = viewController?.widgetArray[index!]["stream"] as? String
        let tag = viewController?.widgetArray[index!]["tag"] as? String
        let auto = viewController?.widgetArray[index!]["auto"] as? Bool
        let min = viewController?.widgetArray[index!]["min"] as? NSNumber
        let max = viewController?.widgetArray[index!]["max"] as? NSNumber
        
        if !(viewController?.active)! || stream == nil || tag == nil || auto == nil || min == nil || max == nil || stream! == "" || tag! == "" || stream!.contains(" ") || tag!.contains(" ") {
            return
        }
        
        let dateStr = "2016-01-01T00:00:00-00:00" // Beginning of the year
    
        var urlStr = (viewController?.baseUrl)! + "events/" + stream!
        if let detail = viewController?.detailItem {
            // Break up urlStr to decrease computing complexity
            urlStr += "/" + ((detail.value(forKey: "apiLogin") as AnyObject).description)! + "?include=$.event_data."
            urlStr += tag! + "&since=" + dateStr + "&limit=1" + "&sort_by=received_at&sort_direction=DESC"
        }
    
        let requestURL: URL = URL(string: urlStr)!
        let task = URLSession.shared.dataTask(with: requestURL, completionHandler: {(data, response, error) in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! NSDictionary
                
                if let event_data = json["event_data"] as? [String: AnyObject] {
                    let tagArray = tag!.components(separatedBy: ".")
                    var value = event_data[tagArray[0]]
                    var valueArr: Dictionary<String, Any>
                    
                    // handles nested tags
                    let arrLength = tagArray.count
                    if arrLength > 1 {
                        valueArr = value as! Dictionary<String, Any>
                        if arrLength > 2 {
                            for index in 1...arrLength - 2 {
                                if tagArray[index] != "" {
                                    valueArr = valueArr[tagArray[index]] as! Dictionary<String, Any>
                                }
                            }
                        }
                        value = valueArr[tagArray[arrLength - 1]] as AnyObject?
                    }

                    DispatchQueue.main.async(execute: {
                        let numberStr = String(describing: value!)
                        let number = Float(numberStr)
                        if number != nil {
                            self.updateGauge(number!, auto: auto!, min: Float(min!), max: Float(max!))
                        }
                    })
                }
            } catch {
                print("no gauge data")
            }
        }) 
        task.resume()
    }

    // Updates gauge min, max, and value
    func updateGauge(_ value: Float, auto: Bool, min: Float, max: Float) {
        if auto {
            if firstVal { // First auto value goes in center of gauge
                gaugemin = value - 20
                gaugemax = value + 20
                self.firstVal = false
            } else {
                if value > gaugemax { // Adjusts min and max according to value after first
                    gaugemax = value + 20
                } else if value < gaugemin {
                    gaugemin = value - 20
                }
            }
        } else {
            gaugemin = min
            gaugemax = max
        }
        redrawGauge(value)
    }
}

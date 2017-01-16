//
//  singleEventWidget.swift
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
//  Shows the last event of a specified stream and tag

import UIKit

class singleEventWidget: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var valueLabel: UITextView!
    
    var viewController: DetailViewController?
    var index: Int?
    var setPopup = settingsPopup(nibName: "settingsPopup", bundle: nil)
    var timer: Timer?
    
    // Sets timer to check for new data every 2 seconds
    override func awakeFromNib() {
        super.awakeFromNib()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(singleEventWidget.getEvents), userInfo: nil, repeats: true)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Creates new timer when cell is reused - either when readded or refreshed
    override func prepareForReuse() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(singleEventWidget.getEvents), userInfo: nil, repeats: true)
    }
    
    // Creates settings popup when icon is pressed
    @IBAction func eventSettings(_ sender: UIButton) {
        if index == nil {
            return
        }
        
        setPopup.viewController = viewController
        setPopup.name = "Notification"
        setPopup.timer = timer
        setPopup.details = "Prints the last event from a specific key"
        setPopup.index = viewController?.tableView.indexPath(for: self)?.row
        setPopup.showInView(self.superview, animated: true)
    }
    
    // Gets last event in tag - checks every 2 seconds
    func getEvents() {
        if index == nil {
            return
        }
        
        viewController?.widgetArray[index!]["new"] = false
        let stream = (viewController?.widgetArray[index!]["stream"]) as? String
        let tag = (viewController?.widgetArray[index!]["tag"]) as? String
        
        if !(viewController?.active)! || stream == nil || tag == nil || stream! == "" || tag! == "" || stream!.contains(" ") || tag!.contains(" ") {
            self.valueLabel.text = "No Events Available"
            self.dateLabel.text = ""
            return
        }
        
        let dateStr = "2016-01-01T00:00:00-00:00" // Beginning of the year
        var urlStr = (viewController?.baseUrl)! + "events/" + stream!
        if let detail = viewController?.detailItem {
            // Break up urlStr to decrease computing complexity
            urlStr += "/" + ((detail.value(forKey: "apiLogin") as AnyObject).description)! + "?include=$.event_data." + tag!
            urlStr += "&since=" + dateStr + "&limit=1" + "&sort_by=received_at&sort_direction=DESC"
        }
        let requestURL: URL = URL(string: urlStr)!
        let task = URLSession.shared.dataTask(with: requestURL, completionHandler: {(data, response, error) in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! NSDictionary
                
                DispatchQueue.main.async(execute: {
                    self.formatEvents(0, json: json, tag: tag!)
                    
                    if self.valueLabel.text == "" {
                        self.valueLabel.text = "No Events Available for Tag \"" + tag! + "\""
                        self.dateLabel.text = ""
                    }
                    
                 })
            } catch {
                print("no stream data")
                DispatchQueue.main.async(execute: {
                    self.valueLabel.text = "No Events Available for Tag \"" + tag! + "\""
                    self.dateLabel.text = ""
                })
            }
        }) 
        task.resume()
    }
    
    // Format:
    // (value)
    // (date)
    func formatEvents(_ eventNum: Int, json: NSDictionary, tag: String) {
        if let event_data = json["event_data"] as? [String: AnyObject] {
            let tagArray = tag.components(separatedBy: ".")
            var value = event_data[tagArray[0]]
            var valueArr: Dictionary<String, Any>
            
            // For nested tags
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
            
            let time = json["observed_at"] as! String // Time
            
            // Format time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ" // Original date format
            let date = dateFormatter.date(from: time)
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss" // Easy date format
            let dateString = dateFormatter.string(from: date!)
            self.valueLabel.text = String(describing: value!)
            self.dateLabel.text = tag + ": " + dateString
        }
    }
}

//
//  multiEventWidget.swift
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
//  Shows last 10 events from specified stream and tag  

import UIKit

class multiEventWidget: UITableViewCell {

    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var log: UITextView!
    
    var viewController: DetailViewController?
    var index: Int?
    var setPopup = settingsPopup(nibName: "settingsPopup", bundle: nil)
    var timer: Timer?
    
    // Sets timer to check for new data every 2 seconds
    override func awakeFromNib() {
        super.awakeFromNib()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(multiEventWidget.getEvents), userInfo: nil, repeats: true)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Creates new timer in case of new cell or refreshed cell
    override func prepareForReuse() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(multiEventWidget.getEvents), userInfo: nil, repeats: true)
    }
    
    // Creates settings popup when icon is pressed
    @IBAction func eventSettings(_ sender: UIButton) {
        if index == nil {
            return
        }
        
        setPopup.viewController = viewController
        setPopup.name = "Log: Multi"
        setPopup.timer = timer
        setPopup.details = "Prints the last 10 events from a specific key"
        setPopup.index = viewController?.tableView.indexPath(for: self)?.row
        setPopup.tagLabel = tagLabel
        setPopup.showInView(self.superview, animated: true)
    }

    // Checks every 2 seconds for the last 10 events in the tag
    func getEvents() {
        if index == nil {
            return
        }
        
        viewController?.widgetArray[index!]["new"] = false
        let stream = viewController?.widgetArray[index!]["stream"] as? String
        let tag = viewController?.widgetArray[index!]["tag"] as? String
        
        if !(viewController?.active)! || stream == nil || tag == nil || stream! == "" || tag! == "" || stream!.contains(" ") || tag!.contains(" ") {
            return
        }
        
        let dateStr = "2016-01-01T00:00:00-00:00" // Beginning of the year
        var urlStr = (viewController?.baseUrl)! + "events/" + stream!
        if let detail = viewController?.detailItem {
            // Break up urlStr to decrease computing complexity
            urlStr += "/" + ((detail.value(forKey: "apiLogin") as AnyObject).description)! + "?include=$.event_data." + tag! + "&since="
            urlStr += dateStr + "&limit=10" + "&sort_by=received_at&sort_direction=DESC"
        }
        let requestURL: URL = URL(string: urlStr)!
        let task = URLSession.shared.dataTask(with: requestURL, completionHandler: {(data, response, error) in
            let allEvents = String(data: data!, encoding: String.Encoding.utf8)!
            var eventArrayStr = [String]()
            var eventArray = [Dictionary<String, Any>]()
            eventArrayStr = allEvents.components(separatedBy: "\n") // Array of json events as Strings
            if String(describing: eventArrayStr[0]) != "" {
                for index in 0...(eventArrayStr.count - 1) {
                    eventArray.append((self.viewController?.convertStringToDictionary(eventArrayStr[index])!)!) // json string array -> json dictionary array
                }
                
                var count = 0
                DispatchQueue.main.async(execute: {
                    for event in eventArray {
                        self.formatEvents(count, json: event as NSDictionary, tag: tag!) // Make events easy to read
                            count += 1
                    }
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.log.text = "No Events Available"
                })
            }
        }) 
        task.resume()
    }
    
    // Format:
    // date: value
    func formatEvents(_ eventNum: Int, json: NSDictionary, tag: String) {
        if let event_data = json["event_data"] as? [String: AnyObject] {
            let tagArray = tag.components(separatedBy: ".")
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

            let time = json["observed_at"] as! String // Time
                
            // Format time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ" // Original date format
            let date = dateFormatter.date(from: time)
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss" // Easy date format
            let dateString = dateFormatter.string(from: date!)
                
            if eventNum == 0 {
                self.log.text = dateString + ": " + String(describing: value!) // First event
            } else {
                self.log.text.append("\n" + dateString + ": " + String(describing: value!)) // Consecutive events
            }
        }
    }
}

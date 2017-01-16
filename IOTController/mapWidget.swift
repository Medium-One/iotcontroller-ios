//
//  mapWidget.swift
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
//  Shows coordinates on a map from GPS or from sending a string in the form "latitude longitude"

import UIKit
import CoreLocation
import MapKit

class mapWidget: UITableViewCell, MKMapViewDelegate {

    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var map: MKMapView!
    
    var viewController: DetailViewController?
    var index: Int?
    var setPopup = settingsPopup(nibName: "settingsPopup", bundle: nil)
    var timer: Timer?
    
    // Sets timer to check for new data every 2 seconds
    override func awakeFromNib() {
        super.awakeFromNib()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(mapWidget.getEvents), userInfo: nil, repeats: true)
        self.map.removeAnnotations(self.map.annotations)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Deletes old timer and creates new timer
    override func prepareForReuse() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(mapWidget.getEvents), userInfo: nil, repeats: true)
        self.map.removeAnnotations(self.map.annotations)
    }
    
    // Creates settings popup when icon is pressed
    @IBAction func mapSettings(_ sender: UIButton) {
        setPopup.viewController = viewController
        setPopup.name = "Map"
        setPopup.details = "Displays location from a specific key"
        setPopup.index = index
        setPopup.timer = timer
        setPopup.tagLabel = tagLabel
        setPopup.showInView(self.superview, animated: true)
    }
    
    // Gets coordinates from tag ever 2 seconds
    func getEvents() {
        if index == nil {
            return
        }
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
            urlStr += dateStr + "&limit=1" + "&sort_by=received_at&sort_direction=DESC"
        }
        let requestURL: URL = URL(string: urlStr)!
        let task = URLSession.shared.dataTask(with: requestURL, completionHandler: {(data, response, error) in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! NSDictionary
                if let event_data = json["event_data"] as? [String: AnyObject] {
                    let tagArray = tag!.components(separatedBy: ".")
                    var value = event_data[tagArray[0]]
                    
                    // For nested tags
                    var valueArr: Dictionary<String, Any>
                    let arrayLength = tagArray.count
                    if arrayLength > 1 {
                        valueArr = value as! Dictionary<String, Any>
                        if arrayLength > 2 {
                            for index in 1...arrayLength - 2 {
                                valueArr = valueArr[tagArray[index]] as! Dictionary<String, Any>
                            }
                        }
                        value = valueArr[tagArray[arrayLength - 1]] as AnyObject?
                    }
                    
                    DispatchQueue.main.async(execute: {
                        if let value2 = value as! Dictionary<String, Any>?{
                            if let location = value2["device_location"] {
                                self.updateMap(String(describing: location)) // From GPS widget
                            } else {
                                self.updateMap(String(describing: value)) // From string
                            }
                        }
                    })
                }

            } catch {
                print("no stream data")
            }
        }) 
        task.resume()
    }
    
    // Sets pin on map to current coordinates
    func updateMap(_ value: String) {
        var coordinates = value.components(separatedBy: " ")
        if coordinates.count < 2 {
            return
        }
        if let latitude = Double(coordinates[0]) {
            if let longitude = Double(coordinates[1]) {
                let location = CLLocation(latitude: latitude, longitude: longitude)
                
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = location.coordinate
                let annotations = self.map.annotations
                
                // Check if there's a previous location on map and remove it
                if annotations.count > 0 && (annotations[0].coordinate.latitude != annotation.coordinate.latitude || annotations[0].coordinate.longitude != annotation.coordinate.longitude) {
                    self.map.removeAnnotations(annotations)
                    self.map.addAnnotation(annotation)
                } else if annotations.count == 0 {
                    self.map.addAnnotation(annotation)
                }
            }
        }
    }
}

//
//  NewWidget.swift
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
//  Button to add a new widget

import UIKit

class NewWidget: UITableViewCell {
    var viewController: DetailViewController?
    var widgetPopup = addWidgetPopup(nibName: "addWidgetPopup", bundle: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Creates popup to add widget
    @IBAction func addWidget(_ sender: UIButton) {
        widgetPopup.viewController = viewController
        widgetPopup.showInView(self.superview, animated: true)
    }
}

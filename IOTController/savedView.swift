//
//  savedView.swift
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
//  Quick popup for when the widgets are saved

import UIKit

class savedView: UIViewController {

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var viewController: DetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Screen dimensions
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        // Sets frame and top constraint according to screen dimensions
        self.view.frame = CGRect(x: 0 , y: 0, width: screenWidth, height: screenHeight * 6)
        
        let newDistance = 50 + (viewController?.tableView.contentOffset.y)!
        topConstraint.constant = newDistance
        self.view.updateConstraints()

        // Setup popup view
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.popupView.layer.cornerRadius = 5
        self.popupView.layer.shadowOpacity = 0.8
        self.popupView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.popupView.center = self.view.center
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // Shows view and closes view
    func showInView(_ aView: UIView!, animated: Bool)
    {
        
        aView.addSubview(self.view)
        if animated
        {
            self.showAnimate()
        }
        viewDidLoad()
        UIView.animate(withDuration: 0.5, delay: 1.0, options: UIViewAnimationOptions(), animations: {
            self.view.alpha = 0.0;
            }, completion:{(finished : Bool)  in
                if (finished)
                {
                    self.view.removeFromSuperview()
                }
        });
                
    }
    
    // Intro animation
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

}

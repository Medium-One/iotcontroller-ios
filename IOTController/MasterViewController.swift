//
//  MasterViewController.swift
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
//  Displays and saves all profiles

import UIKit
import CoreData
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

// Color settings for profiles
extension UIColor {
    var coreImageColor: CoreImage.CIColor {
        return CoreImage.CIColor(color: self)
    }
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let color = coreImageColor
        return (color.red, color.green, color.blue, color.alpha)
    }
}

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil

    var colors = [UIColor]()
    var cellColors = [UIColor]()
    var colorCounter = 0

    var names = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        addColors()
    }
    
    func addColors() { // Creates color gradient on main screen
        colors.removeAll()
        colors.append(UIColor(red: 83/255, green: 189/255, blue: 211/255, alpha: 1))
        colors.append(UIColor(red: 87/255, green: 180/255, blue: 209/255, alpha: 1))
        colors.append(UIColor(red: 91/255, green: 168/255, blue: 207/255, alpha: 1))
        colors.append(UIColor(red: 93/255, green: 158/255, blue: 207/255, alpha: 1))
        colors.append(UIColor(red: 95/255, green: 146/255, blue: 212/255, alpha: 1))
        colors.append(UIColor(red: 94/255, green: 136/255, blue: 213/255, alpha: 1))
        colors.append(UIColor(red: 95/255, green: 122/255, blue: 208/255, alpha: 1))
        colors.append(UIColor(red: 100/255, green: 115/255, blue: 213/255, alpha: 1))
        colors.append(UIColor(red: 95/255, green: 122/255, blue: 208/255, alpha: 1))
        colors.append(UIColor(red: 94/255, green: 136/255, blue: 213/255, alpha: 1))
        colors.append(UIColor(red: 95/255, green: 146/255, blue: 212/255, alpha: 1))
        colors.append(UIColor(red: 93/255, green: 158/255, blue: 207/255, alpha: 1))
        colors.append(UIColor(red: 91/255, green: 168/255, blue: 207/255, alpha: 1))
        colors.append(UIColor(red: 87/255, green: 180/255, blue: 209/255, alpha: 1))
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        addColors()
        tableView.reloadData()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(_ sender: AnyObject) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into: context)
             
        // Creates object for new profile
        newManagedObject.setValue("", forKey: "apiLogin")
        newManagedObject.setValue("", forKey: "apiPassword")
        newManagedObject.setValue("", forKey: "apiKey")
        newManagedObject.setValue("new", forKey: "name")
        newManagedObject.setValue("{\"type\": \"newWidget\"}", forKey: "widgets")
        newManagedObject.setValue(0, forKey: "sandbox")

        
        // Save the context.
        do {
            try context.save()
        } catch {
            abort()
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
            let object = self.fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                NotificationCenter.default.addObserver(self, selector: #selector(MasterViewController.methodOfReceivedNotification(_:)), name:NSNotification.Name(rawValue: "NotificationIdentifier"), object: nil)
            }
        }
    }

    func methodOfReceivedNotification(_ notification: Notification){
        let context = self.fetchedResultsController.managedObjectContext
        // Save the context.
        do {
            try context.save()
        } catch {
            abort()
        }

    }


    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! profileCell
        configureCell(cell, indexPath: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }

    func configureCell(_ cell: profileCell, indexPath: IndexPath) {
        let object = self.fetchedResultsController.object(at: indexPath) as! NSManagedObject
        cell.name.text = object.value(forKey: "name") as? String
        
        // Set cell color
        var colorIndex = indexPath.row
        while colorIndex > colors.count - 1 {
            colorIndex -= 14
        }
        cell.color.backgroundColor = colors[colorIndex]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.delete(self.fetchedResultsController.object(at: indexPath) as! NSManagedObject)
                
            do {
                try context.save()
            } catch {
                abort()
            }
        }
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Project", in: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             abort()
        }
        
        return _fetchedResultsController!
    }
    
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)], with: .fade)
                tableView.reloadData()
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
                tableView.reloadData()
            case .update:
                print("update")
                self.configureCell(tableView.cellForRow(at: indexPath!) as! profileCell, indexPath: indexPath!)
            case .move:
                tableView.deleteRows(at: [indexPath!], with: .fade)
                tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

}


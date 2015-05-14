//
//  AppDelegate.swift
//  SqLT-Cafe
//
//  Created by 杉山元和 on 2015/04/16.
//  Copyright (c) 2015年 __MEXEL_STUDIO__. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var openRecentMenu: NSMenu!
    @IBOutlet weak var executeSqlMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        openRecentMenu.delegate = self
        resetRecentItem()
    }

    // MARK: - menu
    @IBAction func openDocument(sender: NSMenuItem) {
        var openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsOtherFileTypes = false
        openPanel.allowedFileTypes = ["sqlite"]
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let filePath: NSURL = openPanel.URL {
                    var filePathStr: String = (filePath.path != nil) ? filePath.path! : ""
                    if NSFileManager.defaultManager().fileExistsAtPath(filePathStr) {
                        let ud: NSUserDefaults = NSUserDefaults.standardUserDefaults()
                        if (ud.objectForKey("recentPaths") as? [[String: String]]) == nil  {
                            ud.setObject([[String:String]](), forKey: "recentPaths")
                        }
                        var recentPaths: [[String:String]] = ud.objectForKey("recentPaths") as! [[String:String]]
                        if recentPaths.filter({ (str) -> Bool in
                            str["path"] == filePathStr
                        }).count == 0 {
                            let filename: String = (filePath.lastPathComponent != nil) ? filePath.lastPathComponent! : ""
                            recentPaths.append(["filename": filename, "path": filePathStr])
                        }
                        ud.setObject(recentPaths, forKey: "recentPaths")

                        self.resetRecentItem()

                        if let vc: ViewController = _viewController {
                            if let w: NSWindow = vc.view.window {
                                if w.visible == false {
                                    w.orderFront(nil)
                                }
                            }
                            self.executeSqlMenuItem.enabled = true
                            vc.openSqlite(filePath.path!)
                        }
                    }
                }
            }
        }
    }

    func menuNeedsUpdate(menu: NSMenu) {}

    func openRecentFile(sender: NSMenuItem) {
        if let recent: [[String: String]] = NSUserDefaults.standardUserDefaults().objectForKey("recentPaths") as? [[String: String]] {
            let index: Int = openRecentMenu.indexOfItem(sender)
            if let filePath: String = recent[index]["path"] {
                if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                    if let vc: ViewController = _viewController {
                        if let w: NSWindow = vc.view.window {
                            if w.visible == false {
                                w.orderFront(nil)
                            }
                        }
                        executeSqlMenuItem.enabled = true
                        vc.openSqlite(filePath)
                    }
                }
            }
        }
    }

    @IBAction func clearRecentDocuments(sender: NSMenuItem) {
        let ud: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        ud.setObject([[String:String]](), forKey: "recentPaths")
        resetRecentItem()
    }

    func resetRecentItem() {
        openRecentMenu.removeAllItems()
        openRecentMenu.addItemWithTitle("Clear", action: "clearRecentDocuments:", keyEquivalent: "")
        openRecentMenu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        if let recent: [[String: String]] = NSUserDefaults.standardUserDefaults().objectForKey("recentPaths") as? [[String: String]] {
            for item in recent {
                openRecentMenu.insertItemWithTitle(item["filename"]!, action: "openRecentFile:", keyEquivalent: "", atIndex: 0)
            }
        }
    }

    // MARK: - application
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.mexelout.SqLT_Cafe" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1] as! NSURL
        return appSupportURL.URLByAppendingPathComponent("com.mexelout.SqLT_Cafe")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("SqLT_Cafe", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        let propertiesOpt = self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey], error: &error)
        if let properties = propertiesOpt {
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else if error!.code == NSFileReadNoSuchFileError {
            error = nil
            fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil, error: &error)
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SqLT_Cafe.storedata")
            if coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
                coordinator = nil
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error!)
            return nil
        } else {
            return coordinator
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSApplication.sharedApplication().presentError(error!)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
                return .TerminateCancel
            }
            
            if !moc.hasChanges {
                return .TerminateNow
            }
            
            var error: NSError? = nil
            if !moc.save(&error) {
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(error!)
                if (result) {
                    return .TerminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButtonWithTitle(quitButton)
                alert.addButtonWithTitle(cancelButton)
                
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .TerminateCancel
                }
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }

    // 閉じるボタンでアプリ終了するかどうか(trueでアプリ終了、デフォルトはfalse)
//    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
//        return true
//    }

}


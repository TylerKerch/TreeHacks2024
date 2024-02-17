//
//  AppDelegate.swift
//  frontend
//
//  Created by Samuel Yuan on 2/17/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }

    }
    
    
    @objc func readScreen() {
        // Code to read screen content goes here
    }

    @objc func moveCursor() {
        // Code to move cursor goes here
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}


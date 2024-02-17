//
//  AppDelegate.swift
//  frontend
//
//  Created by Samuel Yuan on 2/17/24.
//

import Cocoa
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    var hotKey: HotKey?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        hotKey = HotKey(key: .k, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = {
            ScreenReader.readScreenContents()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}


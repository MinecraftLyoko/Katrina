//
//  ViewController.swift
//  SwiftMinecraftSlack
//
//  Created by Rhett Rogers on 10/9/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var stopButton: NSButton?
    var playerLabel: NSTextField?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userJoinedGame:", name: NotificationString.UserJoinedGame.rawValue, object: nil)
        
        setupUI()
        
        // Do any additional setup after loading the view.
    }
    
    func userJoinedGame(not: NSNotification) {
        if let info = not.userInfo, player = info["Player"] as? Player {
            MinecraftServer.instance.addPlayer(player)
        }

        
    }
    
    func setupUI() {
        playerLabel = NSTextField(frame: NSRect(x: (view.frame.width / 2) - 50, y: view.frame.height - 60, width: 100, height: 40))
        stopButton = NSButton(frame: NSRect(x: 0, y: 0, width: 100, height: 30))
        
        
        updateInfo()
        
        view.addSubview(playerLabel!)
        view.addSubview(stopButton!)
    }
    
    func updateInfo() {
//        playerLabel?.in
        
        stopButton?.title = "Stop Server"
        stopButton?.target = self
        stopButton?.action = "stopServerButton"
        
    }
    
    func stopServerButton() {
        Command.stop()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}


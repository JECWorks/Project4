//
//  WindowController.swift
//  Project4
//
//  Created by Jason Cox on 5/27/24.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet var addressEntry: NSTextField!
    

    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.titleVisibility = .hidden
    }

}

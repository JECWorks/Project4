//
//  ViewController.swift
//  Project4
//
//  Created by Jason Cox on 5/27/24.
//

import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate, NSGestureRecognizerDelegate, NSTouchBarDelegate {
    
    var rows: NSStackView!
    var selectedWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1: Create the stack view and add it to our view
        rows = NSStackView()
        rows.orientation = .vertical
        rows.distribution = .fillEqually
        rows.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rows)
        
        // 2: Create Auto Layout constraints that pin the stack view to the edges of its container
        rows.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        rows.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        rows.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        rows.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // 3: Create an initial column that contains a single webview
        let column = NSStackView(views: [makeWebView()])
        column.distribution = .fillEqually
        
        // 4: Add this column to the 'rows' stack view
        rows.addArrangedSubview(column)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func urlEntered(_ sender: NSTextField) {
        guard let selected = selectedWebView else {return}
            
        // attempt to convert the user's text into a URL
        if let url = URL(string: sender.stringValue) {
                // it worked? -> Load it!
                selected.load(URLRequest(url: url))
        
        }
    }
    
    @IBAction func navigationClicked(_ sender: NSSegmentedControl) {
        // make sure we have a web view selected
        guard let selected = selectedWebView else {return}
        
        if sender.selectedSegment == 0 {
            // back was tapped
            selected.goBack()
        } else {
            // forward was tapped
            selected.goForward()
        }
    }
    
    @IBAction func adjustRows(_ sender: NSSegmentedControl) {
        
        if sender.selectedSegment == 0 {
            // we're adding a new row
            
            // count how many columns we have so far
            // typecast the new rows.arrangedSubview as NSStackView
            let columnCount = (rows.arrangedSubviews[0] as! NSStackView).arrangedSubviews.count
            
            // make a new array of web views that contain the correct number of columns
            let viewArray = (0 ..< columnCount).map { _ in makeWebView() }
            
            // use that web view array to create a new stack view
            let row = NSStackView(views: viewArray)
            
            // make the stack view size its children equally, then add it to our "rows" array
            row.distribution = .fillEqually
            rows.addArrangedSubview(row)
        } else {
            // we're deleting a row
            
            // make sure we have at least two rows
            guard rows.arrangedSubviews.count > 1 else {return}
            
            // pull out the final row, and make sure it's a stack view
            guard let rowToRemove = rows.arrangedSubviews.last as? NSStackView else {return}
            
            // loop through each web view in the row, removing it from the screen
            for cell in rowToRemove.arrangedSubviews {
                cell.removeFromSuperview()
            }
            
            // finally, remove th whole stack view row
            rows.removeArrangedSubview(rowToRemove)
        }
    }
    
    @IBAction func adjustColumns(_ sender: NSSegmentedControl) {
        
        if sender.selectedSegment == 0 {
            // we need to add a column
            for case let row as NSStackView in rows.arrangedSubviews {
                // loop over each row and add a new web view to it
                row.addArrangedSubview(makeWebView())
            }
        } else {
            // we need to dete a column
            // pull out the first of our rows
            guard let firstRow = rows.arrangedSubviews.first as? NSStackView else {return}
            
            // make sure it has at least two columns
            guard firstRow.arrangedSubviews.count > 1 else {return}
            
            // if we are still here it means it's safe to delete a column
            for case let row as NSStackView in rows.arrangedSubviews {
                // loop over every row
                if let last = row.arrangedSubviews.last {
                    // pull out the last web view in this column and remove it using the two-step process
                    row.removeArrangedSubview(last)
                    last.removeFromSuperview()
                }
            }
        }
    }
    
    func makeWebView() -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.wantsLayer = true
        webView.load(URLRequest(url: URL(string: "https://www.apple.com")!))
        
        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(webViewClicked))
        recognizer.delegate = self
        webView.addGestureRecognizer(recognizer)
        
        if selectedWebView == nil {
            select(webView: webView)
        }
        
        return webView
    }
    
    func select(webView: WKWebView) {
        selectedWebView = webView
        selectedWebView.layer?.borderWidth = 4
        selectedWebView.layer?.borderColor = NSColor.blue.cgColor
        
        if let windowController = view.window?.windowController as? WindowController {
            windowController.addressEntry.stringValue = selectedWebView.url?.absoluteString ?? ""
        }
    }
    
    @objc func webViewClicked(recognizer: NSClickGestureRecognizer) {
        guard let newSelectedWebView = recognizer.view as? WKWebView else {return}
        
        // deselect the currently selected web view if there is one
        if let selected = selectedWebView {
            selected.layer?.borderWidth = 0
        }
        
        // select the new one
        select(webView: newSelectedWebView)
    }
    
    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        if gestureRecognizer.view == selectedWebView {
            return false
        } else {
            return true
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard webView == selectedWebView else {return}
        
        if let windowController = view.window?.windowController as? WindowController {
            windowController.addressEntry.stringValue = webView.url?.absoluteString ?? ""
        }
    }
    
    @available(OSX 10.12.2, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        default:
            return nil
        }
    }
    
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        // enable the Customize Touch Bar menu item
        NSApp.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        // create a Touch Bar with a unique identifier, making ViewController its delegate
        let touchBar = NSTouchBar()
        touchBar.customizationIdentifier = NSTouchBar.CustomizationIdentifier("com.JECWorks.project4")
        touchBar.delegate = self
        
        // set up some meaningful defaults
        touchBar.defaultItemIdentifiers = [.navigation, .adjustGrid, .enterAddress, .sharingPicker]
        
        // make the address entry button sit in the center of the bar
        touchBar.principalItemIdentifier = .enterAddress
        
        // allow the user to customize these four controls
        touchBar.customizationAllowedItemIdentifiers = [.sharingPicker, .adjustGrid, .adjustCols, .adjustRows]
        
        // but don't let them take off the URL entry button
        touchBar.customizationRequiredItemIdentifiers = [.enterAddress]
        
        return touchBar
    }
    
}

extension NSTouchBarItem.Identifier {
    static let navigation = NSTouchBarItem.Identifier("com.JECWorks.project4.navigation")
    static let enterAddress = NSTouchBarItem.Identifier("com.JECWorks.project4.enterAddress")
    static let sharingPicker = NSTouchBarItem.Identifier("com.JECWorks.project4.sharingPicker")
    static let adjustGrid = NSTouchBarItem.Identifier("com.JECWorks.project4.adjustGrid")
    static let adjustRows = NSTouchBarItem.Identifier("com.JECWorks.project4.adjustRows")
    static let adjustCols = NSTouchBarItem.Identifier("com.JECWorks.project4.adjustCols")
}

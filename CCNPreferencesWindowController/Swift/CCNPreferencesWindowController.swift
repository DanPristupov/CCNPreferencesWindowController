//
//  CCNPreferencesWindowController.swift
//
//  Original Objective-C code created by Frank Gregor on 16/01/15, adapted by Bruno Vandekerkhove on 30/08/15.
//  Copyright (c) 2015 cocoa:naut. All rights reserved.
//

//
//  The MIT License (MIT)
//  Copyright © 2014 Frank Gregor, <phranck@cocoanaut.com>
//  http://cocoanaut.mit-license.org
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the “Software”), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// 

import AppKit

let CCNPreferencesToolbarIdentifier = "PreferencesMainToolbar"
let CCNPreferencesToolbarSegmentedControlIdentifier = "PreferencesToolbarSegmentedControl"
let CCNPreferencesWindowFrameAutoSaveName = "PreferencesWindowFrameAutoSaveName"
let CCNPreferencesDefaultWindowRect = NSMakeRect(0, 0, 420, 230)
let CCNPreferencesDefaultTitle = "PreferencesWindow: default window title with segmented control in toolbar"
let CCNPreferencesToolbarSegmentedControlItemInset = NSMakeSize(36, 12)
let escapeKey = 53

// MARK: - Preferences Window Controller

//
//  A protocol adopted by classes that handle icon family data.
//
class CCNPreferencesWindowController : NSWindowController, NSToolbarDelegate, NSWindowDelegate {
    
    fileprivate var toolbar: NSToolbar?
    fileprivate var segmentedControl: NSSegmentedControl?
    fileprivate var toolbarDefaultItemIdentifiers: [String]?
    
    /// The preference panels this preferences window controller displays.
    var viewControllers = [CCNPreferencesWindowControllerProtocol]() {
        didSet {
            setupToolbar()
        }
    }
    
    fileprivate var activeViewController: CCNPreferencesWindowControllerProtocol?
    
    ////////////////////////////////////////////////////////////////////////////////
    /// @name Constructors
    ////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Constructors
    
    /// Initialize a new preferences window controller.
    init() {
        
        super.init(window: nil)

        let styleMask: NSWindowStyleMask = [.titled, .closable, .miniaturizable, .unifiedTitleAndToolbar]
        window = CCNPreferencesWindow(contentRect: CCNPreferencesDefaultWindowRect, styleMask: styleMask, backing: .buffered, defer: true)
        
        window?.isMovableByWindowBackground = true

    }
    
    /// Initializes a new preferences window controller with the given coder
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    /// @name Preferences Window Behaviour
    ////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Preferences Window Behaviour
    
    ///
    ///  Determines whether the preferences window's titlebar draws its background,
    ///  allowing all buttons to show - and click - through.
    ///  In general this is only useful when the preferences window has a full sized content view.
    ///
    ///  The value defaults to false.
    ///
    var titleAppearsTransparent = false {
        didSet {
            
            window?.titlebarAppearsTransparent = titleAppearsTransparent
            
        }
    }
    
    ///
    ///  Determines whether or not the toolbar shows a basline separator.
    ///
    ///  The value defaults to true.
    ///
    var showToolbarSeparator = true {
        didSet {
            
            window?.toolbar?.showsBaselineSeparator = showToolbarSeparator
            
        }
    }
    
    ///
    ///  If true the toolbar will also be visible when there's only one preferencesViewController.
    //
    ///  The value defaults to true.
    ///
    var showToolbarWithSingleViewController = true
    
    ///
    ///  Determines whether or not the toolbar is presented as a segmented control or as a genuine toolbar with
    ///  NSToolbarItem instances.
    ///
    ///  The latter's the default behaviour.
    ///
    var showToolbarItemsAsSegmentedControl = false {
        didSet {
            if showToolbarItemsAsSegmentedControl != oldValue {
                toolbarDefaultItemIdentifiers = nil
                centerToolbarItems = true
                setupToolbar()
            }
        }
    }
    
    ///
    ///  Determines whether or not the toolbar's items are centered. This property is ignored if the toolbar is
    ///  presented as a segmented control.
    ///
    ///  Defaults to true.
    ///
    var centerToolbarItems = true {
        didSet {
            if centerToolbarItems != oldValue {
                toolbarDefaultItemIdentifiers = nil
                setupToolbar()
            }
        }
    }
    
    ///
    ///  If true, the preferences window's content view is embedded in an NSVisualEffectView using the
    ///  NSVisualEffectBlendingModeBehindWindow blending mode.
    ///
    ///  The value defaults to false.
    ///
    var allowsVibrancy = false {
        didSet {
            if activeViewController != nil {
                activateViewController(activeViewController!, animate: true)
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    /// @name Show & Hide Preferences Window
    ////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Show & Hide Preferences Window
    
    ///
    ///  Show the preferences window.
    ///
    func showPreferencesWindow() {
        
        if window!.isVisible {
            return
        }
        
        window?.alphaValue = 0.0
        showWindow(self)
        window?.makeKeyAndOrderFront(self)
        NSApplication.shared().activate(ignoringOtherApps: true)
        
        if window?.toolbar != nil {
            
            if showToolbarItemsAsSegmentedControl {
                segmentedControl?.selectSegment(withTag: 0)
            }
            else if toolbarDefaultItemIdentifiers != nil && toolbarDefaultItemIdentifiers!.count > 0 {
                window?.toolbar!.selectedItemIdentifier = toolbarDefaultItemIdentifiers![(centerToolbarItems ? 1 : 0)]
            }
            
        }
        
        if activeViewController == nil {
            activateViewController(viewControllers[0], animate:false)
            window?.center()
        }
        
        window?.alphaValue = 1.0
        
    }
    
    ///
    ///  Hide the preferences window.
    ///
    func dismissPreferencesWindow() {
        
        close()
        
    }
    
    // MARK: Private functions
    
    fileprivate func setupToolbar() {
        
        window?.toolbar = nil
        toolbar = nil
        toolbarDefaultItemIdentifiers = nil
        
        if showToolbarWithSingleViewController || showToolbarItemsAsSegmentedControl || viewControllers.count > 1 {
            
            toolbar = NSToolbar(identifier: CCNPreferencesToolbarIdentifier)
            
            if showToolbarItemsAsSegmentedControl {
                
                toolbar?.allowsUserCustomization = false
                toolbar?.autosavesConfiguration = false
                toolbar?.displayMode = .iconOnly
                
                setupSegmentedControl()
                
            }
            else {
                
                toolbar?.allowsUserCustomization = true
                toolbar?.autosavesConfiguration = true
                
            }
            
            toolbar?.showsBaselineSeparator = showToolbarSeparator
            toolbar?.delegate = self
            window?.toolbar = toolbar
            
        }
        
    }
    
    fileprivate func setupSegmentedControl() {
        
        segmentedControl = NSSegmentedControl()
        segmentedControl?.segmentCount = viewControllers.count
        segmentedControl?.segmentStyle = .texturedSquare
        segmentedControl?.target = self
        segmentedControl?.action = #selector(CCNPreferencesWindowController.segmentedControlAction(_:))
        segmentedControl?.identifier = CCNPreferencesToolbarSegmentedControlIdentifier
        
        if let cell = segmentedControl?.cell as? NSSegmentedCell {
            cell.controlSize = .regular
            cell.trackingMode = .selectOne
        }
        
        let segmentSize = maxSegmentSizeForCurrentViewControllers()
        
        let vcCount = CGFloat(viewControllers.count)
        let segmentWidth = segmentSize.width * vcCount + vcCount + 1.0
        let segmentHeight = segmentSize.height
        segmentedControl?.frame = NSMakeRect(0, 0, segmentWidth, segmentHeight)
        
        var i = 0
        for viewController in viewControllers {
            
            segmentedControl?.setLabel(viewController.preferencesTitle(), forSegment: i)
            segmentedControl?.setWidth(segmentSize.width, forSegment: i)
            if let cell = segmentedControl?.cell as? NSSegmentedCell {
                i += 1;
                cell.setTag(i, forSegment: i)
            }
            
        }
        
    }
    
    fileprivate func maxSegmentSizeForCurrentViewControllers() -> NSSize {
        
        var maxSize = NSMakeSize(42, 0)
        
        for viewController in viewControllers {
            
            let title = viewController.preferencesTitle()
            let titleSize = title.size(withAttributes: [NSFontAttributeName: NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))])
            
            if titleSize.width + CCNPreferencesToolbarSegmentedControlItemInset.width > maxSize.width {
                let maxWidth = titleSize.width + CCNPreferencesToolbarSegmentedControlItemInset.width
                let maxHeight = titleSize.height + CCNPreferencesToolbarSegmentedControlItemInset.height
                maxSize = NSMakeSize(maxWidth, maxHeight)
            }
            
        }
        
        return maxSize
        
    }
    
    fileprivate func activateViewController(_ viewController: CCNPreferencesWindowControllerProtocol, animate: Bool) {
        
        if let preferencesViewController = viewController as? NSViewController {
            
            let viewControllerFrame = preferencesViewController.view.frame
            
            if  let currentWindowFrame = window?.frame,
                let frameRectForContentRect = window?.frameRect(forContentRect: viewControllerFrame) {
                    
                    let deltaX = NSWidth(currentWindowFrame) - NSWidth(frameRectForContentRect)
                    let deltaY = NSHeight(currentWindowFrame) - NSHeight(frameRectForContentRect)
                    let newWindowFrame = NSMakeRect(NSMinX(currentWindowFrame) + (centerToolbarItems ? deltaX / 2 : 0), NSMinY(currentWindowFrame) + deltaY, NSWidth(frameRectForContentRect), NSHeight(frameRectForContentRect))
                    
                    if showToolbarItemsAsSegmentedControl {
                        window?.title = CCNPreferencesDefaultTitle
                    }
                    else {
                        window?.title = viewController.preferencesTitle() as String
                    }
                    
                    let newView = preferencesViewController.view
                    newView.frame.origin = NSMakePoint(0, 0)
                    newView.alphaValue = 0.0
                    newView.autoresizingMask = NSAutoresizingMaskOptions()
                    
                    if let previousViewController = activeViewController as? NSViewController {
                        previousViewController.view.removeFromSuperview()
                    }
                    
                    if allowsVibrancy {
                        let effectView = NSVisualEffectView(frame: newView.frame)
                        effectView.blendingMode = .behindWindow
                        effectView.addSubview(newView)
                        window?.contentView!.addSubview(effectView)
                    }
                    else {
                        window?.contentView!.addSubview(newView)
                    }
                    
                    if let firstResponder = viewController.firstResponder?() {
                        window?.makeFirstResponder(firstResponder)
                    }
                    
                    NSAnimationContext.runAnimationGroup({
                        (context: NSAnimationContext) -> Void in
                        context.duration = (animate ? 0.25 : 0.0)
                        context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                        self.window?.animator().setFrame(newWindowFrame, display: true)
                        newView.animator().alphaValue = 1.0
                        }) {
                            () -> Void in
                            self.activeViewController = viewController
                    }
                    
            }
            
        }
        
    }
    
    fileprivate func viewControllerWithIdentifier(_ identifier: NSString) -> CCNPreferencesWindowControllerProtocol? {
        
        for viewController in viewControllers {
            if viewController.preferencesIdentifier() == identifier as String {
                return viewController
            }
        }
        
        return nil
        
    }
    
    // MARK: Toolbar Delegate Protocol
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: String, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        if itemIdentifier == NSToolbarFlexibleSpaceItemIdentifier {
            return nil
        }
        else if itemIdentifier == CCNPreferencesToolbarSegmentedControlIdentifier {
            
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.view = segmentedControl
            
            return toolbarItem
            
        }
        else {
            
            if let viewController = viewControllerWithIdentifier(itemIdentifier as NSString) {
                
                let identifier = viewController.preferencesIdentifier()
                let label = viewController.preferencesTitle()
                let icon = viewController.preferencesIcon()
                
                let toolbarItem = NSToolbarItem(itemIdentifier: identifier as String)
                toolbarItem.label = label
                toolbarItem.paletteLabel = label
                toolbarItem.image = icon
                if let tooltip = viewController.preferencesToolTip?() {
                    toolbarItem.toolTip = tooltip
                }
                toolbarItem.target = self
                toolbarItem.action = #selector(CCNPreferencesWindowController.toolbarItemAction(_:))
                
                return toolbarItem
                
            }
            
        }
        
        return nil
        
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
        
        if toolbarDefaultItemIdentifiers == nil && viewControllers.count > 0 {
            
            toolbarDefaultItemIdentifiers = [String]()
            
            if showToolbarItemsAsSegmentedControl {
                
                toolbarDefaultItemIdentifiers?.append(NSToolbarFlexibleSpaceItemIdentifier)
                toolbarDefaultItemIdentifiers?.append(CCNPreferencesToolbarSegmentedControlIdentifier)
                toolbarDefaultItemIdentifiers?.append(NSToolbarFlexibleSpaceItemIdentifier)
                
            }
            else {
                
                if centerToolbarItems {
                    toolbarDefaultItemIdentifiers?.append(NSToolbarFlexibleSpaceItemIdentifier)
                }
                
                for viewController in viewControllers {
                    toolbarDefaultItemIdentifiers?.append(viewController.preferencesIdentifier())
                }
                
                if centerToolbarItems {
                    toolbarDefaultItemIdentifiers?.append(NSToolbarFlexibleSpaceItemIdentifier)
                }
                
            }
            
        }
        
        return toolbarDefaultItemIdentifiers!
        
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
        
        return toolbarDefaultItemIdentifiers(toolbar)
        
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
        
        return toolbarDefaultItemIdentifiers(toolbar)
        
    }
    
    func toolbarItemAction(_ toolbarItem: NSToolbarItem) {
        
        if  activeViewController != nil
            && activeViewController!.preferencesIdentifier() != toolbarItem.itemIdentifier,
            let viewController = viewControllerWithIdentifier(toolbarItem.itemIdentifier as NSString) {
                activateViewController(viewController, animate: true)
        }
        
    }
    
    func segmentedControlAction(_ control: NSSegmentedControl) {
        
        if  let cell = control.cell as? NSSegmentedCell {
            
            let viewController = viewControllers[cell.tag(forSegment: control.selectedSegment)]
            
            if activeViewController?.preferencesIdentifier() != viewController.preferencesIdentifier() {
                activateViewController(viewController, animate: true)
            }
            
        }
        
    }
    
}

// MARK: - Preferences Window

///
///  A preferences window.
///
class CCNPreferencesWindow : NSWindow {
    
    
    ///
    ///  Initialize a new preferences window.
    ///
    ///  - parameters:
    ///     - contentRect: The new window's content rect.
    ///     - styleMask: The new window's style mask.
    ///     - backing: The buffer type.
    ///     - defer
    ///
    override init(contentRect: NSRect, styleMask style: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
        
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer:flag)
        
        setFrameAutosaveName(CCNPreferencesWindowFrameAutoSaveName)
        setFrameFrom(CCNPreferencesWindowFrameAutoSaveName)
    }

    override func keyDown(with theEvent: NSEvent) {
        
        switch Int(theEvent.keyCode) {
        case escapeKey:
            orderOut(nil)
            close()
        default:
            super.keyDown(with: theEvent)
        }
        
    }
    
}

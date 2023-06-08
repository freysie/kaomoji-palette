import AppKit
import SwiftUI

// TODO: app notarization
//  ✅   keyboard navigation (arrow keys + return)
// TODO: more accessibility element edge cases (e.g. the empty text field thing w/ dummy space)
//  ✅   intercept escape key when closing popover so it doesn’t send escape key to other apps
//  ✅   prevent double-clicking from inserting twice the kaomoji (//▽//)(//▽//)
// TODO: settings: customizable keyboard shortcut (ﾉД`)
// TODO: settings: customizable categories
// TODO: settings: edit existing kaomoji on double click
// TODO: settings: import/export?
// TODO: perfect positioning of popover when shown in Discord (and other WebKit apps?)
//  ❇️   detach popover when moved by window background (but what is going on with this wrt collection view???)
// TODO: make the “recently used” be “frequently used” instead and/or add “favorites”
// TODO: show regular mouse cursor while mousing over picker
// TODO: do something about the varying widths of kaomoji other than just ellipsizing? 🫣

let popoverSize = NSSize(width: 320, height: 358)
//let popoverSize = NSSize(width: 320, height: 368) // for use with search field

func l(_ key: String) -> String { NSLocalizedString(key, comment: "") }

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  static let shared = NSApp.delegate as! AppDelegate

  var popover: NSPopover?
  var positioningWindow: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    if !AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) {
      NSLog("Accessibility permissions needed.")
    }

#if DEBUG
    //showPicker(at: CGEvent(source: nil)?.unflippedLocation ?? .zero)
    //showSettingsWindow(nil)
#endif

//     NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) {
//       print($0)
//     }

    NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
      // FIXME: find another way (￣▽￣*)ゞ (use carbon hotkeys? or nonactivating panel?)
      if event.keyCode == 53, popover?.isShown == true, popover?.isDetached == false {
        popover?.close()
        return
      }

      guard event.charactersIgnoringModifiers == " ",
            event.modifierFlags.contains(.control),
            event.modifierFlags.contains(.option),
            event.modifierFlags.contains(.command) else { return }

      // NSLog("ヽ(°〇°)ﾉ")

      showPickerAtInsertionPoint()
    }

    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [self] event in
      if popover?.isDetached != true { popover?.close() }
    }

    NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [self] event in
      if popover?.isDetached != true { popover?.close() }
    }

//    NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [self] event in
//      if popover?.isDetached != true { popover?.close() }
//      return event
//    }

    // let w = NSWindow(contentViewController: CollectionViewController())
    // //w.styleMask.insert(.nonactivatingPanel)
    // //w.setValue(true, forKey: "preventsActivation")
    // w.setContentSize(popoverSize)
    // w.orderFrontRegardless()
    // //print(w.frame)
  }

  func showPicker(at point: NSPoint) {
    //let positioningWindow = NSPanel()
    //positioningWindow.styleMask = [.borderless, .nonactivatingPanel]
    let positioningWindow = NSWindow()
    positioningWindow.styleMask = .borderless
    positioningWindow.contentView = NSView()
    positioningWindow.setContentSize(NSSize(width: 10, height: 10))
    positioningWindow.setFrameTopLeftPoint(point)
    positioningWindow.alphaValue = 0
    //positioningWindow.setValue(true, forKey: "preventsActivation")
    positioningWindow.orderFrontRegardless()

    // class ViewController: NSViewController {
    //   convenience init() { self.init(nibName: nil, bundle: nil) }
    //   override func loadView() { view = NSView() }
    // }

    let collectionViewController = CollectionViewController()
    //let collectionViewController = ViewController()
    collectionViewController.preferredContentSize = popoverSize

    let popover = NSPopover()
    popover.delegate = self
    popover.behavior = .transient
    popover.animates = false
    popover.contentViewController = collectionViewController
    popover.contentSize = popoverSize

    self.popover?.close()
    self.popover = popover
    self.positioningWindow = positioningWindow

    popover.show(relativeTo: .zero, of: positioningWindow.contentView!, preferredEdge: .minY)

//    if let controlsHeader = collectionViewController.collectionView?.supplementaryView(
//      forElementKind: NSCollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)
//    ) as? CollectionViewControlsHeader {
//      controlsHeader.searchField.becomeFirstResponder()
//    }

    if let popoverWindow = popover.value(forKey: "_popoverWindow") as? NSPanel {
      //print(popoverWindow)
      //print(popoverWindow.isFloatingPanel, popoverWindow.styleMask, popoverWindow.becomesKeyOnlyIfNeeded)
//      popoverWindow.hidesOnDeactivate = false
//      popoverWindow.canHide = false
//      popoverWindow.becomesKeyOnlyIfNeeded = true

      popoverWindow.level = .floating
      popoverWindow.isMovableByWindowBackground = true

      //popoverWindow.setValue(true, forKey: "hasActiveAppearance")
      //popoverWindow.setValue(true, forKey: "forceActiveControls")
      //popoverWindow.setValue(true, forKey: "preventsActivation")
      //popoverWindow.setValue(true, forKey: "avoidsActivation")
      popoverWindow.setValue(true, forKey: "nonactivatingPanel")
      popoverWindow.setValue(true, forKey: "forceMainAppearance")
    }
  }

  var monitor: Any?

  // TODO: if text field is empty: insert dummy space, select it, get bounds, then delete space
  // TODO: figure out why Discord is being weird (doesn’t work with Kaomoji Picker unless you inspect Discord once with Accessibility Inspector after every launch)
  func showPickerAtInsertionPoint() {
    // var attributeNames: CFArray?
    // AXUIElementCopyAttributeNames(AXUIElementCreateSystemWide(), &attributeNames)
    // print(attributeNames as Any)
    // var parameterizedAttributeNames: CFArray?
    // AXUIElementCopyParameterizedAttributeNames(AXUIElementCreateSystemWide(), &parameterizedAttributeNames)
    // print(parameterizedAttributeNames as Any)

    var focusedElement: AnyObject?
    guard AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
      NSLog("failed to get focused element")
      panel.orderFrontRegardless()
      return
    }

    var textMarkerRange: AnyObject?
    if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, "AXSelectedTextMarkerRange" as CFString, &textMarkerRange) == .success {
      var boundsValue: AnyObject?
      guard AXUIElementCopyParameterizedAttributeValue(focusedElement as! AXUIElement, "AXBoundsForTextMarkerRange" as CFString, textMarkerRange!, &boundsValue) == .success else {
        NSLog("failed to find bounds for text marker range")
        return
      }

      var bounds = CGRect.null
      AXValueGetValue(boundsValue as! AXValue, .cgRect, &bounds)
      bounds.origin.x -= 4
      bounds.origin.y = (NSScreen.main?.frame.size.height ?? 0) - bounds.origin.y - bounds.size.height + 10
      //print(bounds)

      return showPicker(at: bounds.origin)
    }

    var selectedRangeValue: AnyObject?
    if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue) == .success {
      var range: CFRange?
      AXValueGetValue(selectedRangeValue as! AXValue, AXValueType(rawValue: kAXValueCFRangeType)!, &range)

      var boundsValue: AnyObject?
      guard AXUIElementCopyParameterizedAttributeValue(focusedElement as! AXUIElement, kAXBoundsForRangeParameterizedAttribute as CFString, selectedRangeValue!, &boundsValue) == .success else {
        NSLog("failed to find bounds for selected text range")
        return
      }

      var bounds = CGRect.null
      AXValueGetValue(boundsValue as! AXValue, .cgRect, &bounds)
      bounds.origin.x -= 4
      bounds.origin.y = (NSScreen.main?.frame.size.height ?? 0) - bounds.origin.y - bounds.size.height + 10
      //print(bounds)

      return showPicker(at: bounds.origin)
    }

    showPicker(at: CGEvent(source: nil)?.unflippedLocation ?? .zero)
    // popover?.perform(Selector((String("detach"))))
  }

  func insertText(_ string: String) {
    guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else { return }

    for chunk in string.chunked(into: 20) {
      var characters = UniChar()
      (chunk as NSString).getCharacters(&characters)
      event.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &characters)
      event.post(tap: .cghidEventTap)
      event.type = .keyUp
      event.post(tap: .cghidEventTap)
      event.type = .keyDown
    }

    DataSource.shared.addKaomojiToRecents(string)

    // --8<----

    // var focusedElement: AnyObject?
    // guard AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
    //   print("failed to get focused element")
    //   return
    // }

    // var value: AnyObject?
    // var rangeValue: AnyObject?
    // AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXValueAttribute as CFString, &value)
    // AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &rangeValue)

    // guard rangeValue != nil else { return print("nil range") }

    // var range = NSRange()
    // AXValueGetValue(rangeValue as! AXValue, .cfRange, &range)

    // let newValue = (value as! NSString).replacingCharacters(in: range, with: string)
    // AXUIElementSetAttributeValue(focusedElement as! AXUIElement, kAXValueAttribute as CFString, newValue as AnyObject)

    // range.length = 0
    // range.location += string.count

    // let newRange = AXValueCreate(.cfRange, &range)
    // AXUIElementSetAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, newRange as AnyObject)
  }

  // MARK: - Settings

  let panel = {
    let size = NSSize(width: popoverSize.width, height: popoverSize.height + 27)

    let collectionViewController = CollectionViewController()
    collectionViewController.mode = .pickerWindow
    collectionViewController.usesMaterialBackground = true
    collectionViewController.preferredContentSize = size

    let window = NSPanel(contentViewController: collectionViewController)
    window.styleMask = [.fullSizeContentView, .utilityWindow, .closable]
    window.titleVisibility = .hidden
    window.isFloatingPanel = true
    window.hidesOnDeactivate = false
    window.animationBehavior = .none
    window.becomesKeyOnlyIfNeeded = false
    window.setContentSize(size)
    window.level = .modalPanel
    window.isMovableByWindowBackground = true
    window.setValue(true, forKey: "forceMainAppearance")

    return window
  }()

  let settingsWindow = {
    let window = NSPanel(contentViewController: NSHostingController(rootView: SettingsView()))
    window.title = l("Kaomoji Picker Settings")
    window.styleMask = [.titled, .nonactivatingPanel, .utilityWindow, .closable, .resizable]
    window.isFloatingPanel = true
    window.hidesOnDeactivate = false
    window.setContentSize(NSSize(width: 499, height: 736))
    window.level = .modalPanel
    return window
  }()

  @objc func showSettingsWindow(_ sender: Any?) {
    popover?.close()
    // TODO: animate the picker popover into the settings panel?? 🤪
    settingsWindow.makeKeyAndOrderFront(nil)
  }

  // MARK: - Popover Delegate

  func popoverWillClose(_ notification: Notification) {
    popover?.animates = true
    //monitor.map(NSEvent.removeCarbonMonitor)
  }

  func popoverDidShow(_ notification: Notification) {
    //print(#function)
    //print((popover, popover?.value(forKey: "positioningWindow")))
    //guard let popover, let window = popover.value(forKey: "positioningWindow") as? NSWindow else { return }

    // print(NSApp.windows as NSArray)

    guard let popoverController = popover?.contentViewController as? CollectionViewController else { return }
    //print("aaaaaaa")
    //popoverController.view.window?.makeKeyAndOrderFront(nil)
    //print(popoverController.view.window as Any)
    //print(popoverController.view.window?.makeFirstResponder(popoverController.searchField) as Any)
    //print(popoverController.view.window?.firstResponder as Any)
    popoverController.view.window?.makeFirstResponder(popoverController.searchField)
    popoverController.view.window?.makeKeyAndOrderFront(nil)
    popoverController.view.window?.makeKey()
    popoverController.view.window?.orderFrontRegardless()

    //popoverController.view.window?.makeKey()
    //NSApp.activate(ignoringOtherApps: true)
    //popoverController.view.window?.orderFront(nil)
    //DispatchQueue.main.async {
    //  popoverController.view.window?.makeFirstResponder(popoverController.searchField)
    //}
  }

  // func popoverDidClose(_ notification: Notification) {
  //   DispatchQueue.main.async {
  //     self.positioningWindow?.close()
  //   }
  // }

  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    true
  }

  func detachableWindow(for popover: NSPopover) -> NSWindow? {
    guard let popoverController = self.popover?.contentViewController as? CollectionViewController else { return nil }
    guard let panelController = panel.contentViewController as? CollectionViewController else { return nil }
    panelController.scrollView.scrollToVisible(popoverController.scrollView.contentView.bounds)
    panelController.view.window?.makeFirstResponder(panelController.searchField)
    return panel
  }

  func popoverDidDetach(_ popover: NSPopover) {
    guard let stackView = (popover.contentViewController as? CollectionViewController)?.stackView else { return }
    stackView.edgeInsets.top = 27
  }
}

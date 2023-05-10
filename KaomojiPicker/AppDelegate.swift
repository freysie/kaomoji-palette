import AppKit
import SwiftUI
import HotKey
//import Combine

// TODO: settings!
// TODO: do something about the varying widths?
// TODO: keyboard navigation (arrow keys + return)
// TODO: drag kaomoji out of the picker
// TODO: more accessibility element edge cases (e.g. the empty text field thing w/ dummy space)
// TODO: detach popover when moved by window background
// TODO: intercept escape key when closing popover so it doesn’t send escape key to other apps
// TODO: make the “recently used” be “frequently used” instead and/or add “favorites”
// TODO: show regular mouse cursor while mousing over picker (or is this just an issue with my OpenCore-Legacy-Patcher-patched macOS??)
// TODO: prevent double-clicking from inserting two kaomoji

let popoverSize = NSSize(width: 320, height: 358)
//let popoverSize = NSSize(width: 320, height: 368)

func l(_ key: String) -> String { NSLocalizedString(key, comment: "") }

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  var keyMonitor: Any?
  var mouseMonitor: Any?
  var popover: NSPopover?
  var positioningWindow: NSWindow?
  //var subscription: AnyCancellable?

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary) else {
      print("Accessibility permissions needed.")
      NSApp.terminate(nil)
      return
    }

//    defaults.register(defaults: [
//      "Categories": Array(kaomojiSectionTitles.dropFirst()),
//      "Kaomoji": Array(kaomoji.dropFirst()),
//    ])

    //showSettingsWindow(nil)

//    kaomoji[0] = defaults.stringArray(forKey: "Recents") ?? []

    //UserDefaults.standard.stringArray(forKey: "Recents")
    //UserDefaults.standard.stringArray(forKey: "Kaomoji")
    //UserDefaults.standard.stringArray(forKey: "Categories")
    //UserDefaults.standard.stringArray(forKey: "Favorites")
    //UserDefaults.standard.dictionary(forKey: "UsageHistory")

    // NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) {
    //   print($0)
    // }

    keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
      // FIXME: find another way (￣▽￣*)ゞ (use carbon hotkeys? or nonactivating panel?)
      if event.keyCode == 53, popover?.isShown == true, popover?.isDetached == false {
        popover?.close()
        return
      }

      guard event.charactersIgnoringModifiers == " ",
            event.modifierFlags.contains(.control),
            event.modifierFlags.contains(.option),
            event.modifierFlags.contains(.command) else { return }

      //print("ヽ(°〇°)ﾉ")

      showPickerAtInsertionPoint()
    }

    mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [self] event in
      guard popover?.isDetached == false else { return }
      popover?.close()
    }

    showPicker(at: CGEvent(source: nil)?.unflippedLocation ?? .zero)

    // let w = NSWindow(contentViewController: CollectionViewController())
    // //w.styleMask.insert(.nonactivatingPanel)
    // //w.setValue(true, forKey: "preventsActivation")
    // w.setContentSize(popoverSize)
    // w.orderFrontRegardless()
    // //print(w.frame)
  }

  var leftArrowHotKey: HotKey!
  var rightArrowHotKey: HotKey!
  var upArrowHotKey: HotKey!
  var downArrowHotKey: HotKey!
  var escapeHotKey: HotKey!
  var returnHotKey: HotKey!

  func showPicker(at point: NSPoint) {
    //print(#function)
    //let w = NSWindow(contentViewController: CollectionViewController())
    ////w.styleMask.insert(.nonactivatingPanel)
    //w.setValue(true, forKey: "preventsActivation")
    //w.setContentSize(popoverSize)
    //w.orderFrontRegardless()
    //print(w.frame)

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

    let collectionViewController = CollectionViewController()
    collectionViewController.preferredContentSize = popoverSize

    let popover = NSPopover()
    popover.delegate = self
    popover.behavior = .transient
    popover.contentViewController = collectionViewController
    popover.contentSize = popoverSize

//    func beginSelection() {
//      if collectionViewController.collectionView.selectionIndexPaths.isEmpty {
//        collectionViewController.collectionView.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: .nearestHorizontalEdge)
//      }
//    }

//    leftArrowHotKey = HotKey(key: .leftArrow, modifiers: [])
//    leftArrowHotKey.keyDownHandler = { beginSelection(); collectionViewController.collectionView.moveLeft(nil) }
//    rightArrowHotKey = HotKey(key: .rightArrow, modifiers: [])
//    rightArrowHotKey.keyDownHandler = { beginSelection(); collectionViewController.collectionView.moveRight(nil) }
//    upArrowHotKey = HotKey(key: .upArrow, modifiers: [])
//    upArrowHotKey.keyDownHandler = { beginSelection(); collectionViewController.collectionView.moveUp(nil) }
//    downArrowHotKey = HotKey(key: .downArrow, modifiers: [])
//    downArrowHotKey.keyDownHandler = { beginSelection(); collectionViewController.collectionView.moveDown(nil) }
//    escapeHotKey = HotKey(key: .escape, modifiers: [])
//    escapeHotKey.keyDownHandler = { self.popover?.close() }
//    returnHotKey = HotKey(key: .return, modifiers: [])
//    returnHotKey.keyDownHandler = { print("aaaaaaaa") }

    popover.animates = false
    popover.show(relativeTo: .zero, of: positioningWindow.contentView!, preferredEdge: .minY)
    popover.animates = true

    //collectionViewController.collectionView.focusRingType = .exterior
    collectionViewController.collectionView.becomeFirstResponder()

    if let popoverWindow = popover.value(forKey: "_popoverWindow") as? NSPanel {
      //print(popoverWindow)
      //print(popoverWindow.isFloatingPanel, popoverWindow.styleMask, popoverWindow.becomesKeyOnlyIfNeeded)
      //popoverWindow.styleMask.insert(.utilityWindow)
      //popoverWindow.styleMask.insert(.nonactivatingPanel)
      //popoverWindow.isFloatingPanel = true
      //popoverWindow.becomesKeyOnlyIfNeeded = true

      popoverWindow.level = .floating
      //popoverWindow.isMovableByWindowBackground = true
      //popoverWindow.setValue(true, forKey: "hasActiveAppearance")
      //popoverWindow.setValue(true, forKey: "nonactivatingPanel")
      //popoverWindow.setValue(true, forKey: "avoidsActivation")
      //popoverWindow.setValue(true, forKey: "forceActiveControls")
      popoverWindow.setValue(true, forKey: "forceMainAppearance")
      popoverWindow.setValue(true, forKey: "preventsActivation")

      //let modalSession = NSApp.beginModalSession(for: positioningWindow)
      //NSApp.runModalSession(modalSession)
    }

    self.popover?.close()
    self.popover = popover
    self.positioningWindow = positioningWindow
  }

  func showPickerAtInsertionPoint() {
    // var attributeNames: CFArray?
    // AXUIElementCopyAttributeNames(AXUIElementCreateSystemWide(), &attributeNames)
    // print(attributeNames as Any)
    // var parameterizedAttributeNames: CFArray?
    // AXUIElementCopyParameterizedAttributeNames(AXUIElementCreateSystemWide(), &parameterizedAttributeNames)
    // print(parameterizedAttributeNames as Any)

    var focusedElement: AnyObject?
    guard AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
      print("failed to get focused element")

      var focusedApp: AnyObject?
      guard AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success else { return }
      print(focusedApp as Any)

      return
    }

    //AXSelectedTextMarkerRange
    //AXStartTextMarker

    var textMarkerRange: AnyObject?
    if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, "AXSelectedTextMarkerRange" as CFString, &textMarkerRange) == .success {
      //print(range as Any)

      //let endMarker = AXTextMarkerRangeCopyEndMarker(textMarkerRange as! AXTextMarkerRange)
      //print(endMarker)
      //print(AXTextMarkerGetLength(endMarker))

      var boundsValue: AnyObject?
      guard AXUIElementCopyParameterizedAttributeValue(focusedElement as! AXUIElement, "AXBoundsForTextMarkerRange" as CFString, textMarkerRange!, &boundsValue) == .success else {
        print("failed to find bounds for text marker range")
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
        print("failed to find bounds for selected text range")
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
  }

  func insertText(_ string: String) {
    print(#function, string)
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

//    var recents = defaults.stringArray(forKey: "Recents") ?? []
//    recents.insert(string, at: 0)
//    recents = Array(recents.uniqued().prefix(maxRecents))
//    defaults.set(recents, forKey: "Recents")
//    kaomoji[0] = recents

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

    // --8<----

    //var errorInfo: NSDictionary?
    //NSAppleScript(source: "tell application \"System Events\" to keystroke \"\(string)\"")?.executeAndReturnError(&errorInfo)
    //print(errorInfo as Any)
  }

//  class KaomojiSettingsWindow: NSWindow {
//    // FIXME: this doesn’t work (i blame swiftui)
//    override var isMiniaturizable: Bool { false }
//    override var isZoomable: Bool { false }
//  }

  let settingsWindow = {
    let window = NSPanel(contentViewController: NSHostingController(rootView: SettingsView()))
    window.title = l("Kaomoji Picker Settings")
    window.styleMask = [.titled, .nonactivatingPanel, .utilityWindow, .closable]
    window.isFloatingPanel = true
    window.hidesOnDeactivate = false
    //window.becomesKeyOnlyIfNeeded = true
    window.level = .modalPanel
    return window
  }()

  @objc func showSettingsWindow(_ sender: Any?) {
    popover?.close()
    //ProcessSerialNumber psn = { 0, kCurrentProcess };
    //TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    //NSApp.setActivationPolicy(.regular)
    //var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
    //TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
    //DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
      //settingsWindow.makeKeyAndOrderFront(nil)
    //settingsWindow.orderFrontRegardless()
    //settingsWindow.orderFront(nil)
    settingsWindow.makeKeyAndOrderFront(nil)
      //settingsWindow.makeMain()
    //}
  }

  // MARK: -

  func popoverWillClose(_ notification: Notification) {
    leftArrowHotKey = nil
    rightArrowHotKey = nil
    upArrowHotKey = nil
    downArrowHotKey = nil
    escapeHotKey = nil
    returnHotKey = nil
  }

  func popoverDidShow(_ notification: Notification) {
    //print((popover, popover?.value(forKey: "positioningWindow")))
    //guard let popover, let window = popover.value(forKey: "positioningWindow") as? NSWindow else { return }

    // print(NSApp.windows as NSArray)

//    DispatchQueue.main.async {
//      self.subscription = NotificationCenter.default
//        .publisher(for: NSWindow.didChangeOcclusionStateNotification, object: window)
//        .sink { _ in
//          print(window.occlusionState.contains(.visible))
//          popover.close()
//          self.subscription?.cancel()
//        }
//    }
  }

  // func popoverDidClose(_ notification: Notification) {
  //   DispatchQueue.main.async {
  //     self.positioningWindow?.close()
  //   }
  // }

  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    true
  }

  func popoverDidDetach(_ popover: NSPopover) {
    var frame = popover.contentViewController!.view.frame
    frame.size.height -= 27
    popover.contentViewController!.view.frame = frame

    // if let popoverWindow = popover.value(forKey: "_popoverWindow") as? NSWindow {
    //   print(popoverWindow)
    // }

    //print(popover.contentViewController?.view.window?.standardWindowButton(.closeButton)?.frame)
    //popover.contentViewController!.view.window!.standardWindowButton(.closeButton)!.frame = popover.contentViewController!.view.window!.standardWindowButton(.closeButton)!.frame.insetBy(dx: -5, dy: -5)
  }
}

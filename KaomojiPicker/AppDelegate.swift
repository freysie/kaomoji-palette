import AppKit
import SwiftUI

//  ✅   keyboard navigation (arrow keys + return)
//  ✅   intercept escape key when closing popover so it doesn’t send escape key to other apps
//  ✅   prevent double-clicking from inserting twice the kaomoji (//▽//)(//▽//)
//  ✅   settings: import/export?
//  ✅   perfect positioning of popover
//  ❇️   detachable picker panel
//  ✅   show regular mouse cursor while mousing over picker
//  ✅   add kaomoji inserted by drag-and-drop to recents
//  ✅   make search field work in detached panel
//  ❇️   detach popover when moved by any part of window background, including within collection view

// TODO: settings: customizable categories
// TODO: settings: edit existing kaomoji on double click
// FIXME: fix any regressions in the settings window (＞﹏＜)
// FIXME: NSCollectionView keyboard navigation not accounting for section headers
// FIXME: keep search field in view hierarchy even when scrolling waaay down

// TODO: app notarization
// TODO: more accessibility element edge cases (e.g. the empty text field thing w/ dummy space)
// TODO: settings: customizable keyboard shortcut (ﾉД`)
// TODO: persisted panel position changing with active app à la system’s character picker?
// TODO: try out variable-width items in the picker view? (ᗒᗣᗕ)՞
// TODO: make the “recently used” be “frequently used” instead and/or add “favorites”
// TODO: when dragging kaomoji out of the picker, don’t disappear the original collection view item
// TODO: collection view item background colors should be grayed out sometimes like in the system symbols palette
// TODO: add Sparkle or something for automatic updates

let popoverSize = NSSize(width: 320, height: 358)
//let popoverSize = NSSize(width: 320, height: 44)
let titlebarHeight = 27.0

func l(_ key: String) -> String { NSLocalizedString(key, comment: "") }

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  static let shared = NSApp.delegate as! AppDelegate

  var popover: NSPopover?
  var positioningWindow: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard ProcessInfo.processInfo.environment["XCODE_IS_RUNNING_FOR_PREVIEWS"] != "1" else { return }

//    UserDefaults.standard.register(defaults: [
//      "NSUseAnimatedFocusRing": false
//    ])

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
  }

  // MARK: - Showing Picker

  func showPicker(at point: NSPoint, insertionPointHeight: CGFloat = 2) {
    guard !panel.isVisible else { return }

    settingsWindow.performClose(nil)

    let positioningWindow = NSPanel()
    positioningWindow.styleMask = [.borderless, .nonactivatingPanel]
    positioningWindow.contentView = NSView()
    positioningWindow.setContentSize(NSSize(width: 2, height: insertionPointHeight))
    positioningWindow.setFrameTopLeftPoint(point)
    positioningWindow.alphaValue = 0
    positioningWindow.orderFrontRegardless()

    let collectionViewController = CollectionViewController()
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
    //popover.show(relativeTo: .zero, of: positioningWindow.contentView!, preferredEdge: .maxY)

    if let popoverWindow = popover.value(forKey: "_popoverWindow") as? NSPanel {
      tryBlock { popoverWindow.setValue(true, forKey: "forceMainAppearance") }
      //print(tryBlock { popoverWindow.setValue(true, forKey: "animates") } as Any)
    }
  }

  // TODO: unless there’s a better way — if text field is empty: insert dummy space, select it, get bounds, then delete space
  // TODO: figure out why Discord is being weird (doesn’t work with Kaomoji Picker unless you inspect Discord once with Accessibility Inspector after every launch)
  func showPickerAtInsertionPoint(withFallback: Bool = true) {
    guard let element = AXUIElement.systemWide.focusedUIElement else { return panel.orderFrontRegardless() }
    guard var range = element.selectedTextRange else { return }

    if range.length == 0, element.bounds(for: range)?.size == .zero {
      range.location = max(0, range.location - 1)
      range.length = 1
    }

    if var bounds = element.bounds(for: range), bounds.size != .zero {
      bounds.origin.y += bounds.size.height
      showPicker(at: bounds.origin, insertionPointHeight: bounds.size.height)
    } else if let frame = element.frame, var frame = NSScreen.convertFromQuartz(frame) {
      if let searchButton = element.searchButton, let size = searchButton.size { frame.origin.x += size.width }
      frame.origin.y += frame.size.height
      showPicker(at: frame.origin, insertionPointHeight: frame.size.height)
    }



    //print(range)
//    var wasEmpty = false
//    if element.bounds(for: range)?.size == .zero {
//      wasEmpty = true
//      element.value = " "
//      element.selectedTextRange = CFRange(location: range.location, length: 1)
//      if let newRange = element.selectedTextRange { range = newRange }
//    }
    //if wasEmpty { element.value = "" }

    //    print(AXUIElement.systemWide.focusedUIElement as Any)
    //    print(AXUIElement.systemWide.focusedUIElement?.value as Any)
    //    print(AXUIElement.systemWide.focusedUIElement?.primaryScreenHeight as Any)
    //    print(AXUIElement.systemWide.focusedUIElement?.insertionPointLineNumber as Any)
    //    if let range = AXUIElement.systemWide.focusedUIElement?.selectedTextRange {
    //      print(range)
    //      print(AXUIElement.systemWide.focusedUIElement?.attributedString(for: range) as Any)
    //      return showPicker(at: bounds.origin, insertionPointHeight: bounds.size.height)
    //    }


//    var focusedElement: AnyObject?
//    guard AXUIElementCopyAttributeValue(
//      AXUIElementCreateSystemWide(),
//      kAXFocusedUIElementAttribute as CFString,
//      &focusedElement
//    ) == .success else {
//      NSLog("failed to get focused element")
//      panel.orderFrontRegardless()
//      return
//    }
//
//    var textMarkerRange: AnyObject?
//    var selectedRangeValue: AnyObject?
//
//    if AXUIElementCopyAttributeValue(
//      focusedElement as! AXUIElement,
//      "AXSelectedTextMarkerRange" as CFString,
//      &textMarkerRange
//    ) == .success {
//      var boundsValue: AnyObject?
//      guard AXUIElementCopyParameterizedAttributeValue(
//        focusedElement as! AXUIElement,
//        "AXBoundsForTextMarkerRange" as CFString,
//        textMarkerRange!,
//        &boundsValue
//      ) == .success else {
//        NSLog("failed to find bounds for selected text marker range")
//        return
//      }
//
//      var bounds = CGRect.null
//      AXValueGetValue(boundsValue as! AXValue, .cgRect, &bounds)
//      bounds.origin.y = (NSScreen.main?.frame.size.height ?? 0) - bounds.origin.y
//
//      return showPicker(at: bounds.origin, insertionPointHeight: bounds.size.height)
//    } else if AXUIElementCopyAttributeValue(
//      focusedElement as! AXUIElement,
//      kAXSelectedTextRangeAttribute as CFString,
//      &selectedRangeValue
//    ) == .success {
//      var range: CFRange?
//      AXValueGetValue(selectedRangeValue as! AXValue, AXValueType(rawValue: kAXValueCFRangeType)!, &range)
//
//      var boundsValue: AnyObject?
//      guard AXUIElementCopyParameterizedAttributeValue(
//        focusedElement as! AXUIElement,
//        kAXBoundsForRangeParameterizedAttribute as CFString,
//        selectedRangeValue!,
//        &boundsValue
//      ) == .success else {
//        NSLog("failed to find bounds for selected text range")
//        return
//      }
//
//      var bounds = CGRect.null
//      bounds.origin.y = (NSScreen.main?.frame.size.height ?? 0) - bounds.origin.y
//
//      return showPicker(at: bounds.origin, insertionPointHeight: bounds.size.height)
//    } else {
//      NSLog("fallback")
//    }
  }

  // MARK: - Inserting Text

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
  }

  // MARK: - Panel

  let panel = {
    let size = NSSize(width: popoverSize.width, height: popoverSize.height + titlebarHeight)

    let collectionViewController = CollectionViewController()
    collectionViewController.mode = .pickerPanel
    collectionViewController.usesMaterialBackground = true
    collectionViewController.preferredContentSize = size

    let window = PickerPanel(contentViewController: collectionViewController)
    window.styleMask = [.borderless, .closable, .fullSizeContentView, .utilityWindow, .nonactivatingPanel]
    window.isMovableByWindowBackground = true
    window.hidesOnDeactivate = false
    window.allowsToolTipsWhenApplicationIsInactive = true
    //window.level = .floating
    window.animationBehavior = .utilityWindow
    window.isFloatingPanel = true
    window.becomesKeyOnlyIfNeeded = true
    tryBlock { window.setValue(true, forKey: "forceMainAppearance") }
    window.setContentSize(size)

    return window
  }()

  // MARK: - Settings

  let settingsWindow = {
    let window = NSPanel(contentViewController: NSHostingController(rootView: SettingsView()))
    window.title = l("Kaomoji Picker Settings")
    window.styleMask = [.titled, .utilityWindow, .closable, .resizable]
    window.hidesOnDeactivate = false
    window.level = .modalPanel
    window.isFloatingPanel = true
    // window.becomesKeyOnlyIfNeeded = true
    window.setContentSize(NSSize(width: 499, height: 736))
    return window
  }()

  @objc func showSettingsWindow(_ sender: Any?) {
    popover?.close()
    panel.close()
    // TODO: animate the picker popover into the settings panel?? 🤪
    //settingsWindow.makeMain()
    settingsWindow.makeKeyAndOrderFront(nil)
    //NSApp.activate(ignoringOtherApps: true)
  }

  // MARK: - Popover Delegate

  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    true
  }

  func popoverDidDetach(_ popover: NSPopover) {
    print(#function)
//    guard let stackView = (popover.contentViewController as? CollectionViewController)?.stackView else { return }
//    stackView.edgeInsets.top = titlebarHeight
//    print()
  }

  func detachableWindow(for popover: NSPopover) -> NSWindow? {
    guard let popoverController = self.popover?.contentViewController as? CollectionViewController else { return nil }
    guard let panelController = panel.contentViewController as? CollectionViewController else { return nil }
    panelController.scrollView.scrollToVisible(popoverController.scrollView.contentView.bounds)
    panelController.searchField?.stringValue = popoverController.searchField?.stringValue ?? ""
    panelController.view.window?.makeFirstResponder(panelController.searchField)
    tryBlock { panel.setValue(true, forKey: "preventsActivation") }
    return panel
  }

  func popoverDidShow(_ notification: Notification) {
    guard let popoverController = popover?.contentViewController as? CollectionViewController else { return }
    popoverController.view.window?.makeFirstResponder(popoverController.searchField)
  }

  func popoverWillClose(_ notification: Notification) {
    // print(#function)
    popover?.animates = true
  }

  func popoverDidClose(_ notification: Notification) {
    // print(#function)
    positioningWindow?.close()
  }
}

// MARK: -

class PickerPanel: NSPanel {
  override var canBecomeKey: Bool { true }
}

import AppKit
import CoreGraphics

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSWindowDelegate {
  var observers = Set<AXObserver>()
  var monitor: Any?
  var popover: NSPopover?

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary) else {
      print("Accessibility permissions needed.")
      NSApp.terminate(nil)
      return
    }

//    NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) {
//      print($0)
//    }

    monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
      guard event.charactersIgnoringModifiers == " ",
            event.modifierFlags.contains(.control),
            event.modifierFlags.contains(.option),
            event.modifierFlags.contains(.command) else { return }

      print("ヽ(°〇°)ﾉ")

      showPickerAtInsertionPoint()
    }

    //for app in NSWorkspace.shared.runningApplications  {
//    let pid = 45193 as pid_t
//    let axApp = AXUIElementCreateApplication(pid)
//    var observer: AXObserver!
//    AXObserverCreate(pid, { _, element, notification, _ in
//      //print("\(element) \(notification)")
//      //var value: AnyObject?
//      //AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
//      //kAXSelectedTextRangeAttribute
//      //AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, "yeeeet" as CFString)
//      //print(value as? String)
//
//    }, &observer)
//
//    observers.insert(observer)
//
//    CFRunLoopAddSource(RunLoop.current.getCFRunLoop(), AXObserverGetRunLoopSource(observer), CFRunLoopMode.defaultMode)
//
//    let this = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
//    //AXObserverAddNotification(observer, axApp, kAXApplicationHiddenNotification as CFString, this)
//    //AXObserverAddNotification(observer, axApp, kAXApplicationShownNotification as CFString, this)
//    //AXObserverAddNotification(observer, axApp, kAXApplicationActivatedNotification as CFString, this)
//    //AXObserverAddNotification(observer, axApp, kAXApplicationDeactivatedNotification as CFString, this)
//    AXObserverAddNotification(observer, axApp, kAXFocusedUIElementChangedNotification as CFString, this)
//    //}

    showPicker(at: CGEvent(source: nil)?.unflippedLocation ?? .zero)
  }

  func showPicker(at point: NSPoint) {
    //let w = NSWindow(contentViewController: KaomojiPickerViewController())
    ////w.styleMask.insert(.nonactivatingPanel)
    //w.setValue(true, forKey: "preventsActivation")
    //w.setContentSize(NSSize(width: 320, height: 358))
    //w.orderFrontRegardless()
    //print(w.frame)

    let fauxWindow = NSWindow()
    fauxWindow.styleMask = .borderless
    fauxWindow.contentView = NSView()
    fauxWindow.setContentSize(NSSize(width: 10, height: 10))
    fauxWindow.setFrameTopLeftPoint(point)
    fauxWindow.alphaValue = 0
    fauxWindow.orderFrontRegardless()

    let popover = NSPopover()
    popover.delegate = self
    popover.behavior = .transient
    popover.contentViewController = KaomojiPickerViewController()
    popover.contentSize = NSSize(width: 320, height: 358)
    //popover.contentViewController!.view.frame = popover.contentViewController!.view.frame.insetBy(dx: 10, dy: 10)
    popover.show(relativeTo: .zero, of: fauxWindow.contentView!, preferredEdge: .minY)

    if let popoverWindow = popover.value(forKey: "_popoverWindow") as? NSWindow {
      print(popoverWindow)
      popoverWindow.level = .floating
      //popoverWindow.setValue(true, forKey: "avoidsActivation")
      //popoverWindow.setValue(true, forKey: "hasActiveAppearance")
      //popoverWindow.setValue(true, forKey: "forceActiveControls")
      //popoverWindow.setValue(true, forKey: "nonactivatingPanel")
      popoverWindow.setValue(true, forKey: "preventsActivation")
      popoverWindow.setValue(true, forKey: "forceMainAppearance")
    }

    self.popover?.close()
    self.popover = popover
  }

  func showPickerAtInsertionPoint() {
    var focusedElement: AnyObject?
    guard AXUIElementCopyAttributeValue(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
      print("failed to get focused element")
      return
    }

    //var names2: CFArray?
    //AXUIElementCopyAttributeNames(focusedElement, &names2)
    //print(names2 as Any)
    //var names: CFArray?
    //AXUIElementCopyParameterizedAttributeNames(focusedElement, &names)
    //print(names as Any)

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

  // MARK: -

  func popoverDidShow(_ notification: Notification) {
    (notification.object as? NSPopover)?.contentViewController?.view.window?.isMovableByWindowBackground = true
  }

  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    true
  }

  func popoverDidDetach(_ popover: NSPopover) {
    var frame = popover.contentViewController!.view.frame
    frame.size.height -= 27
    popover.contentViewController!.view.frame = frame

    if let popoverWindow = popover.value(forKey: "_popoverWindow") as? NSWindow {
      print(popoverWindow)
    }

    //print(popover.contentViewController?.view.window?.standardWindowButton(.closeButton)?.frame)
    //popover.contentViewController!.view.window!.standardWindowButton(.closeButton)!.frame = popover.contentViewController!.view.window!.standardWindowButton(.closeButton)!.frame.insetBy(dx: -5, dy: -5)
  }
}

extension Collection {
  func chunked(into size: Int) -> [SubSequence] {
    var chunks: [SubSequence] = []
    chunks.reserveCapacity((underestimatedCount + size - 1) / size)

    var residual = self[...], splitIndex = startIndex
    while formIndex(&splitIndex, offsetBy: size, limitedBy: endIndex) {
      chunks.append(residual.prefix(upTo: splitIndex))
      residual = residual.suffix(from: splitIndex)
    }

    return residual.isEmpty ? chunks : chunks + CollectionOfOne(residual)
  }
}

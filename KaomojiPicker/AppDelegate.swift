import AppKit
import SwiftUI
import Combine
import InputMethodKit
import KeyboardShortcuts

//  ✅   keyboard navigation (arrow keys + return (+ tab & backtab &c.))
//  ✅   intercept escape key when closing popover so it doesn’t send escape key to other apps
//  ✅   prevent double-clicking from inserting twice the kaomoji (//▽//)(//▽//)
//  ✅   settings: import/export?
//  ✅   perfect popover positioning
//  ❇️   detachable picker panel
//  ✅   show regular mouse cursor while mousing over picker popover
//  ✅   add kaomoji inserted by drag-and-drop to recents
//  ✅   make search field work in detached panel
//  ❇️   detach popover when moved by any part of window background, including within collection view
//  ✅   settings: customizable categories
//  ✅   settings: edit existing kaomoji on double click
//  ✅   settings: customizable keyboard shortcut (ﾉД`)
//  ✅   resolve odd issue where setings window will sometimes somehow open the panel and position it off-screen
//  ✅   unless there’s a better way — if text field is empty: insert dummy space, select it, get bounds, then delete space
//  ✅   figure out why Discord is being weird (doesn’t work unless you inspect Discord once with Accessibility Inspector)

// 1.0
// 👩‍💻 TODO: input method stuff ~~accessibility element edge cases (e.g. the empty text field thing w/ dummy space)~~
// 👩‍💻 FIXME: keep search field in view hierarchy even when scrolling waaay down
// 👩‍💻 FIXME: NSCollectionView keyboard navigation not accounting for section headers
// 👩‍💻 FIXME: fix any regressions in the settings window (＞﹏＜)??
// TODO: app notarization
// TODO: add Sparkle or something for automatic updates

// 1.x
// TODO: when dragging kaomoji out of the picker, don’t disappear the original collection view item
// TODO: collection view item background colors should be grayed out sometimes like in the system symbols palette
// TODO: persist picker panel position per process à la system’s character palette!
// TODO: try out variable-width items in the picker view? (ᗒᗣᗕ)՞
// TODO: add a “Favorites” section and/or let the “Recently Used” be “Frequently Used” instead

let popoverSize = NSSize(width: 320, height: 358)
let titlebarHeight = 27.0

func l(_ key: String) -> String { NSLocalizedString(key, comment: "") }

// TODO:
struct PickerState {
  let position: CGRect
  let scrollPosition: CGPoint
  let searchQuery: String = ""
}

var insertionPointRect = NSRect.zero

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  static let shared = NSApp.delegate as! AppDelegate

  private(set) var popover: NSPopover?
  private(set) var positioningWindow: NSWindow?

  private var server: IMKServer!
  private var candidates: IMKCandidates!

  private var perProcessState = [NSRunningApplication: PickerState]()
  private var subscriptions = Set<AnyCancellable>()

  func applicationWillFinishLaunching(_ notification: Notification) {
    guard ProcessInfo.processInfo.environment["XCODE_IS_RUNNING_FOR_PREVIEWS"] != "1" else { return }

    NSLog("[KaomojiPicker] \(#function) \(ProcessInfo.processInfo.arguments[0])")

    server = IMKServer(name: "local_kaomojipicker_connection", bundleIdentifier: Bundle.main.bundleIdentifier!)
    //server = IMKServer(name: "Kaomoji Picker", controllerClass: InputController.self, delegateClass: NSObject.self)
    //candidates = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel, styleType: kIMKMain)

    //print(server as Any)
    //print(candidates as Any)

//    do {
//      let list = TISCreateInputSourceList(
//        [kTISPropertyInputSourceCategory: kTISCategoryPaletteInputSource] as CFDictionary,
//        false
//      )
//      print(list as Any)
//    }
//
//    do {
//      let list = TISCreateInputSourceList(
//        [kTISPropertyInputSourceCategory: kTISCategoryPaletteInputSource] as CFDictionary,
//        true
//      )
//      print(list as Any)
//    }

    //TISRegisterInputSource(<#T##location: CFURL!##CFURL!#>)

    do {
      let list = TISCreateInputSourceList([kTISPropertyBundleID: Bundle.main.bundleIdentifier!] as CFDictionary, true)
      if let source = (list?.takeUnretainedValue() as? [TISInputSource])?.first {
        print(source)
        print(TISEnableInputSource(source))
        print(TISSelectInputSource(source))
      }
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard ProcessInfo.processInfo.environment["XCODE_IS_RUNNING_FOR_PREVIEWS"] != "1" else { return }

    // TODO: do this for all Electron apps when using accessibility backend?
    if let pid = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Discord" })?.processIdentifier {
      let axApp = AXUIElementCreateApplication(pid)
      let result = AXUIElementSetAttributeValue(axApp, "AXManualAccessibility" as CFString, true as CFTypeRef)
      //print(pid, axApp, result.rawValue)
      NSLog("setting AXManualAccessibility \(result.rawValue == 0 ? "succeeded" : "failed")")
    }

    if !AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) {
      NSLog("accessibility permissions needed")
    }

#if DEBUG
    //showPicker(at: CGEvent(source: nil)?.unflippedLocation ?? .zero)
    //showSettingsWindow(nil)
#endif

//    NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) {
//      print($0)
//    }

//    DistributedNotificationCenter.default()
//      .addObserver(forName: .init("CPKCharacterViewerWindowWillOpenNotification"), object: nil, queue: nil) {
//        print($0)
//      }

//    NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
//      guard event.charactersIgnoringModifiers == " ",
//            event.modifierFlags.contains(.control),
//            event.modifierFlags.contains(.option),
//            event.modifierFlags.contains(.command) else { return }
//
//      //NSLog("ヽ(°〇°)ﾉ")
//      showPickerAtInsertionPoint()
//    }

    KeyboardShortcuts.onKeyDown(for: .showPalette) { [self] in
      if !NSApp.isActive { showPickerAtInsertionPoint() }
    }

    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [self] event in
      if popover?.isDetached != true { popover?.close() }
    }

    NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [self] event in
      if popover?.isDetached != true { popover?.close() }
    }

//    NotificationCenter.default.addObserver(
//      forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil
//    ) { notification in
//      print(notification)
//      print(NSWorkspace.shared.frontmostApplication as Any)
//    }

    NSWorkspace.shared.publisher(for: \.frontmostApplication)
      .sink { print($0 as Any) }
      .store(in: &subscriptions)
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

    if let popoverWindow = popover.value(forKey: "_popoverWindow") as? NSPanel {
      tryBlock { popoverWindow.setValue(true, forKey: "forceMainAppearance") }

      // TODO: exclude from exposé
      //print(popoverWindow.collectionBehavior, popoverWindow.collectionBehavior.rawValue)
      //popoverWindow.collectionBehavior = [.managed, .ignoresCycle, .fullScreenAuxiliary, .canJoinAllSpaces]
      //popoverWindow.isExcludedFromWindowsMenu = true
      //popoverWindow.styleMask.insert(.hudWindow)
    }
  }

  func showPickerAtInsertionPoint(withFallback: Bool = true) {
    NSLog("[KaomojiPicker] \(#function) \(insertionPointRect)")

//    var rect = insertionPointRect
//    rect.origin.y += rect.size.height
//    showPicker(at: rect.origin, insertionPointHeight: rect.size.height)
//    return

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
  }

  // MARK: - Inserting Text

  func insertText(_ string: String) {
    let source = CGEventSource(stateID: .privateState)
    guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else { return }

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

  func insertBackwardDelete() {
    let source = CGEventSource(stateID: .privateState)
    guard let event = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: true) else { return }
    event.post(tap: .cghidEventTap)
    event.type = .keyUp
    event.post(tap: .cghidEventTap)
  }

  // MARK: - Panel

  let panel = {
    let size = NSSize(width: popoverSize.width, height: popoverSize.height + titlebarHeight)

    let collectionViewController = CollectionViewController()
    collectionViewController.collectionStyle = .palettePanel
    collectionViewController.usesMaterialBackground = true
    collectionViewController.preferredContentSize = size

    let window = PalettePanel(contentViewController: collectionViewController)
    window.styleMask = [.borderless, .closable, .fullSizeContentView, .nonactivatingPanel]
    window.isMovableByWindowBackground = true
    window.hidesOnDeactivate = false
    window.allowsToolTipsWhenApplicationIsInactive = true
    window.level = .floating
    if #available(macOS 13.0, *) { window.collectionBehavior = .auxiliary }
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
    window.styleMask = [.titled, .utilityWindow, .closable, .resizable, .nonactivatingPanel]
    window.hidesOnDeactivate = false
    // window.level = .modalPanel
    window.isFloatingPanel = true
    window.becomesKeyOnlyIfNeeded = true
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

  // func popoverDidDetach(_ popover: NSPopover) {
  //   print(#function)
  // }

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
    popover?.animates = true
  }

  func popoverDidClose(_ notification: Notification) {
    positioningWindow?.close()
  }
}

// MARK: -

class PalettePanel: NSPanel {
  override var canBecomeKey: Bool { true }
}

extension KeyboardShortcuts.Name {
  static let showPalette = Self("KPShortcut", default: Shortcut(.space, modifiers: [.control, .option, .command]))
}

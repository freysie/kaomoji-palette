import AppKit
import SwiftUI
import Combine
import InputMethodKit
import Carbon.HIToolbox.TextInputSources
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
//  ✅   resolve odd issue where settings window will sometimes somehow open the panel and position it off-screen
//  ✅   unless there’s a better way — if text field is empty: insert dummy space, select it, get bounds, then delete space
//  ✅   figure out why Discord is being weird (doesn’t work unless you inspect Discord once with Accessibility Inspector)
//  ✅   exclude popover from Exposé

// 1.0
// FIXME: Tahoe regression in detecting whether the input method has been installed (seems related to “Couldn't write values for keys (AppleEnabledThirdPartyInputSources)” error)
// FIXME: Tahoe regression in activating the input method after installation
// FIXME: relaunch on reboot
// TODO: add option for inserting kaomoji with narrow no-break spaces
// ✅ TODO: input method stuff ~~accessibility element edge cases (e.g. the empty text field thing w/ dummy space)~~
// ✅ FIXME: keep search field in view hierarchy even when scrolling waaay down
// ✅ FIXME: NSCollectionView keyboard navigation not accounting for section headers
// FIXME: regressions in the settings window (＞﹏＜)?? (category index off by one when editing)
// FIXME: crash when searching and using keyboard navigation
// TODO: restore scroll position when reopening the palette popover
// TODO: app notarization (＃`Д´)
// TODO: add Sparkle or something for automatic updates
// TODO: figure out exactly how to do automatic updates seeing we’re now an input method

// 1.x
// TODO: persist picker panel position per process à la system’s character palette!
// TODO: don’t jitter on `moveUp:` in collection view
// TODO: focus last category button correctly, even if the section is too small to fill the whole collection view
// TODO: try to get rid of the ±1 index path stuff
// TODO: when dragging kaomoji out of the picker, don’t disappear the original collection view item
// TODO: collection view item background colors should be grayed out sometimes like in the system symbols palette
// TODO: try out variable-width items in the picker view? (ᗒᗣᗕ)՞
// TODO: add a “Favorites” section and/or let the “Recently Used” be “Frequently Used” instead
// TODO: consider if we need a Kaomoji Helper that (handles keyboard shortcuts? and) restarts the input method if it crashes
// TODO: on `moveDown:`, do the thing the system character palette does where it jumps a whole screenful when reaching the edge
// TODO: actually, just do all the keyboard navigation things that the system character palette does — they got it right!
// TODO: better coupling, cleaner architecture

let popoverHeight = if #available(macOS 26, *) { 444 } else { 358 }
let popoverSize = NSSize(width: 320, height: popoverHeight)

let titlebarHeight = if #available(macOS 26, *) { 27.0 + 12.0 } else { 27.0 }

// Don’t ask about this, please.
let panelHeight = if #available(macOS 26, *) {
  popoverSize.height + titlebarHeight - 2.0
} else {
  popoverSize.height + titlebarHeight
}

func l(_ key: String) -> String { NSLocalizedString(key, comment: "") }
func KPLog(_ message: String) { NSLog("[KaomojiPalette] \(message)") }

// TODO:
struct PickerState {
  let position: CGRect
  let scrollPosition: CGPoint
  let searchQuery: String = ""
}

let isRunningForPreviews = ProcessInfo.processInfo.environment["XCODE_IS_RUNNING_FOR_PREVIEWS"] == "1"
let isRunningAsInputMethod = ProcessInfo.processInfo.arguments[0].contains("/Library/Input Methods")

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  static let shared = NSApp.delegate as! AppDelegate

  private(set) var popover: NSPopover?
  private(set) var positioningWindow: NSWindow?
  private(set) var isInserting = false

  private var server: IMKServer!
  private var perProcessState = [NSRunningApplication: PickerState]()
  private var subscriptions = Set<AnyCancellable>()

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard !isRunningForPreviews else { return }

    //KPLog("\(ProcessInfo.processInfo.arguments)")
    //KPLog("\(ProcessInfo.processInfo.environment.keys)")

    server = IMKServer(
      name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String,
      bundleIdentifier: Bundle.main.bundleIdentifier
    )

    if !isRunningAsInputMethod {
      if !AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) {
        KPLog("accessibility permissions needed")
      }

      // TODO: do this for all Electron apps when using accessibility backend?
      if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Discord" }) {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetAttributeValue(axApp, "AXManualAccessibility" as CFString, true as CFTypeRef)
      }
    } else {
      // TODO: don’t rely on accessibility access when running as input method
      // if !CGRequestPostEventAccess() {
      //   KPLog("event posting access needed")
      // }
    }

#if DEBUG
    //showPicker(at: CGEvent(source: nil)?.unflippedLocation ?? .zero)
    //showSettingsWindow(nil)
#endif

    KeyboardShortcuts.onKeyDown(for: .showPalette) { [self] in
      if isRunningAsInputMethod {
        TISInputSource.kaomoji?.select()
      } else if !NSApp.isActive {
        showPickerAtInsertionPoint()
      }
    }

    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [self] _ in
      if popover?.isDetached != true { popover?.close() }
    }

    if #available(macOS 26, *) {
      // In previous versions, we’d close the popover on scroll, but the system doesn’t do that anymore, so we won’t either.
    } else {
      NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [self] _ in
        if popover?.isDetached != true { popover?.close() }
      }
    }

    NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: panel, queue: nil) { _ in
      TISInputSource.kaomoji?.deselect()
    }

    // NotificationCenter.default.addObserver(
    //   forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil
    // ) { notification in
    //   print(notification)
    //   print(NSWorkspace.shared.frontmostApplication as Any)
    // }

    // NSWorkspace.shared.publisher(for: \.frontmostApplication)
    //   .sink { print($0 as Any) }
    //   .store(in: &subscriptions)
  }

  // MARK: - Showing Picker

  func showPicker(at point: NSPoint, insertionPointHeight: CGFloat = 2) {
    guard !panel.isVisible else { return }

    settingsWindow.performClose(nil)

    let positioningWindow = NSPanel()
    positioningWindow.styleMask = [.borderless, .nonactivatingPanel]
    positioningWindow.collectionBehavior = [.transient]
    positioningWindow.contentView = NSView()
    positioningWindow.setContentSize(NSSize(width: 2, height: insertionPointHeight))
    positioningWindow.setFrameTopLeftPoint(NSPoint(x: point.x, y: point.y + insertionPointHeight))
    positioningWindow.alphaValue = 0
    positioningWindow.orderFrontRegardless()

    let collectionViewController = CollectionViewController()
    //collectionViewController.usesMaterialBackground = true
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
    }
  }

  func showPickerAtInsertionPoint(withFallback: Bool = true) {
//    KPLog("\(#function) InputController.current?.insertionPointFrame = \(InputController.current?.insertionPointFrame as Any)")

    if isRunningAsInputMethod {
      if let frame = InputController.current?.insertionPointFrame, frame != .zero {
        showPicker(at: frame.origin, insertionPointHeight: frame.size.height)
      } else {
        panel.orderFrontRegardless()
      }
    } else {
      guard let element = AXUIElement.systemWide.focusedUIElement else { return panel.orderFrontRegardless() }
      guard var range = element.selectedTextRange else { return }

      if range.length == 0, element.bounds(for: range)?.size == .zero {
        range.location = max(0, range.location - 1)
        range.length = 1
      }

      if let bounds = element.bounds(for: range), bounds.size != .zero {
        showPicker(at: bounds.origin, insertionPointHeight: bounds.size.height)
      } else if let frame = element.frame, var frame = NSScreen.convertFromQuartz(frame) {
        if let searchButton = element.searchButton, let size = searchButton.size { frame.origin.x += size.width }
        showPicker(at: frame.origin, insertionPointHeight: frame.size.height)
      }
    }
  }

  // MARK: - Inserting Text

  func insertKaomoji(_ sender: NSCollectionViewItem, withCloseDelay: Bool) {
    guard let kaomoji = sender.representedObject as? String else { return }

    KPLog("\(#function) \(kaomoji) \(InputController.currentSession?.bundleIdentifier() ?? "")")

    isInserting = true
    DataSource.shared.addKaomojiToRecents(kaomoji)

    if panel.isVisible {
      if NSApp.currentEvent?.type == .keyDown {
        NSApp.deactivate()
      }

      insertText(kaomoji)
      isInserting = false
    } else {
      let innerCloseDelay = if #available(macOS 26, *) { 0.0 } else { 0.3 }

      DispatchQueue.main.asyncAfter(deadline: .now() + (withCloseDelay ? 0.5 : 0)) { [self] in
        popover?.close()

        DispatchQueue.main.asyncAfter(deadline: .now() + innerCloseDelay) { [self] in
          NSApp.deactivate()

          insertText(kaomoji)
          isInserting = false

          TISInputSource.kaomoji?.deselect()
        }
      }
    }
  }

  private func insertText(_ string: String) {
    if isRunningAsInputMethod {
      KPLog("\(#function) \(string) \(InputController.currentSession?.bundleIdentifier() ?? "")")
      guard let client = InputController.currentSession else { return }
      client.insertText(string, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    } else {
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
  }

  private func insertBackwardDelete() {
    let source = CGEventSource(stateID: .privateState)
    guard let event = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: true) else { return }
    event.post(tap: .cghidEventTap)
    event.type = .keyUp
    event.post(tap: .cghidEventTap)
  }

  // MARK: - Panel

  private(set) lazy var panel = {
    let size = NSSize(width: popoverSize.width, height: panelHeight)

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
    window.becomesKeyOnlyIfNeeded = if #available(macOS 26, *) { false } else { true }
    tryBlock { window.setValue(true, forKey: "forceMainAppearance") }
    window.setContentSize(size)

    return window
  }()

  // MARK: - Settings

  private(set) lazy var settingsWindow = {
    let window = NSPanel(contentViewController: NSHostingController(rootView: SettingsView()))
    window.title = l("Kaomoji Palette Settings")
    window.styleMask = [.titled, .utilityWindow, .closable, .resizable]
    window.hidesOnDeactivate = false
    // window.level = .modalPanel
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
    NSApp.activate(ignoringOtherApps: true)
    settingsWindow.makeKeyAndOrderFront(nil)
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

    DispatchQueue.main.async { [self] in
      if !panel.isVisible, !isInserting {
        TISInputSource.kaomoji?.deselect()
      }
    }
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
  static let showPalette = Self("KPShortcut", default: Shortcut(.space, modifiers: [.shift, .command]))
}

import SwiftUI
import Carbon.HIToolbox.TextInputSources
import Sparkle

func l(_ key: String) -> String { NSLocalizedString(key, comment: "") }
func KPLog(_ message: String) { NSLog("[KaomojiPalette] \(message)") }

let isRunningForPreviews = ProcessInfo.processInfo.environment["XCODE_IS_RUNNING_FOR_PREVIEWS"] == "1"

@main
struct App: SwiftUI.App {
  @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

  init() {
    guard !isRunningForPreviews else { return }
    
    let window = NSWindow(contentViewController: NSHostingController(rootView: ContentView()))
    //window.styleMask = [.titled, .closable, .fullSizeContentView, .utilityWindow, .hudWindow]
    window.styleMask = [.titled, .closable]
    window.title = l("Kaomoji Palette")
    window.titleVisibility = .hidden
    //window.isMovableByWindowBackground = true
    //window.hidesOnDeactivate = false
    window.makeKeyAndOrderFront(nil)

    // SPUUpdater
  }

  // TODO: convert to MainMenu.xib to support earlier macOS versions
  var body: some Scene {
    Settings { EmptyView() }
      .commands { CommandGroup(replacing: .appSettings) { EmptyView() } }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

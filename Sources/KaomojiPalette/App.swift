import SwiftUI
import Carbon.HIToolbox.TextInputSources

func l(_ key: String) -> String { NSLocalizedString(key, comment: "") }
func KPLog(_ message: String) { NSLog("[KaomojiPalette] \(message)") }

@main
struct App: SwiftUI.App {
  @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

  init() {
    let window = NSWindow(contentViewController: NSHostingController(rootView: ContentView()))
    //window.styleMask = [.titled, .closable, .fullSizeContentView, .utilityWindow, .hudWindow]
    window.styleMask = [.titled, .closable]
    window.title = l("Kaomoji Palette")
    window.titleVisibility = .hidden
    //window.isMovableByWindowBackground = true
    //window.hidesOnDeactivate = false
    window.makeKeyAndOrderFront(nil)
  }

  var body: some Scene {
    Settings { EmptyView() }
      .commands {
        CommandGroup(replacing: .appSettings) {
          EmptyView()
        }
      }

    //_EmptyScene()

//    WindowGroup {
//      ContentView()
//        // .onAppear { TISInputSource.assistiveControl?.disable() }
//    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

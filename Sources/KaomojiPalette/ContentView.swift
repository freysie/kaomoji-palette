import SwiftUI
import Carbon.HIToolbox.TextInputSources

public extension View {
  func modify<Content>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
    transform(self)
  }
}

let homeURL = URL(fileURLWithPath: NSHomeDirectory())
let inputMethodsURL = URL(fileURLWithPath: "Library/Input Methods", relativeTo: homeURL)
let sourceURL = URL(fileURLWithPath: "Kaomoji.app", relativeTo: Bundle.main.sharedSupportURL)
let destinationURL = URL(fileURLWithPath: "Kaomoji.app", relativeTo: inputMethodsURL)

enum InstallationState {
  case notInstalled
  case installed
  case updateAvailable
}

var installationState: InstallationState {
  let sourceInfoURL = sourceURL.appendingPathComponent("Contents/Info.plist")
  let destinationInfoURL = destinationURL.appendingPathComponent("Contents/Info.plist")

  guard let sourceInfo = try? NSDictionary(contentsOf: sourceInfoURL, error: ()) else {
    preconditionFailure("expected input method’s Info.plist to exist")
  }

  guard let destinationInfo = try? NSDictionary(contentsOf: destinationInfoURL, error: ()) else {
    return .notInstalled
  }

  if
    let sourceVersion = sourceInfo["CFBundleVersion"] as? String,
    let sourceShortVersion = sourceInfo["CFBundleShortVersion"] as? String,
    let destinationVersion = destinationInfo["CFBundleVersion"] as? String,
    sourceVersion > destinationVersion
  {
    print("\(sourceShortVersion) (\(sourceVersion)) is available")

    return .updateAvailable
  }

  return .installed
}

// TODO: hmm…
final class Installer: ObservableObject {
  static let shared = Installer()

  @Published private(set) var isInputMethodInstalled = false
  @Published private(set) var inputMethodNeedsUpdate = false

  @Published private(set) var isUpdateAvailable = true {
    didSet { NSApp.dockTile.badgeLabel = isUpdateAvailable ? "1" : nil }
  }
}

struct UpdateButton: View {
  var action: () -> ()

  @Environment(\.controlActiveState) private var controlActiveState

  var body: some View {
    Button(action: {}) {
      Text("Update Available")
      Text(verbatim: "1")
        .font(.system(size: NSFont.smallSystemFontSize, weight: .medium))
        .frame(width: 18, height: 18)
        .multilineTextAlignment(.center)
        .foregroundColor(.white)
        .background(controlActiveState != .inactive ? Color.red : Color.gray)
        .cornerRadius(18 / 2)
    }
    //.modify { if #available(macOS 12, *) { $0.buttonBorderShape(.roundedRectangle) } else { $0 } }
    .buttonStyle(.plain)
    // FIXME: make focusable but last in next-key-view chain
    .focusable(false)
    .padding()
  }
}

struct ContentView: View {
  @State private var state = InstallationState.notInstalled
  @State private var isEnabled = TISInputSource.kaomoji?.isEnabled == true
  @State private var observer: NSObjectProtocol?
  @State private var timer: Timer?
  private var isInstalled: Bool { state != .notInstalled }
  private var isInstalledAndEnabled: Bool { state != .notInstalled && isEnabled }
  @ObservedObject private var installer = Installer.shared
  //@Namespace private var namespace

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(spacing: 0) {
        Spacer()

        VStack(spacing: 30) {
          //Image(systemName: "keyboard")
          //.font(.system(size: 52))
          Image(nsImage: NSApp.applicationIconImage)
            //.resizable()
            //.frame(width: 96, height: 96)
            .imageScale(.large)
            .foregroundColor(.accentColor)

          Text("Kaomoji Palette")
            .font(.largeTitle.weight(.semibold))
            .multilineTextAlignment(.center)

          if !isInstalledAndEnabled {
            Text("To use Kamoji Palette, the kaomoji input method must be enabled.")
          } else {
            Text("The kaomoji input method is enabled.")
          }
        }
        .frame(width: 440)
        .multilineTextAlignment(.center)

        Spacer()

        Divider()

        HStack {
          Spacer()

          Button(action: { NSApp.terminate(nil) }) { Text("Quit").frame(width: 99) }
            .keyboardShortcut(.cancelAction)

          Button(action: !isInstalledAndEnabled ? install : uninstall) {
            Text(!isInstalledAndEnabled ? "Enable" : "Disable").frame(width: 99)
          }
          .keyboardShortcut(
            !isInstalledAndEnabled
            ? .defaultAction
            : KeyboardShortcut(KeyEquivalent(Character(UnicodeScalar(0))))
          )
          //.modify { if #available(macOS 12, *) { $0.prefersDefaultFocus(in: namespace) } else { $0 } }

          Spacer()
        }
        .controlSize(.large)
        .padding()
        .frame(height: 57)
      }

      if installer.isUpdateAvailable {
        UpdateButton(action: {})
      }
    }
    .navigationTitle("Kaomoji Palette")
    .frame(width: 800 / 1.5, height: 600 / 1.5)
    .onAppear(perform: check)
    //.modify { if #available(macOS 12, *) { $0.focusScope(namespace) } else { $0 } }
  }

  private func check() {
    state = installationState
  }

  private func install() {
    do {
      try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    } catch {
      KPLog(error.localizedDescription)
    }

    TISInputSource.register(destinationURL)

    guard let inputSource = TISInputSource.kaomoji else {
      KPLog("input source not found")
      return
    }

    inputSource.enable()

    func checkIfEnabled() {
      if inputSource.isEnabled == true {
        inputSource.select()
        isEnabled = true
        NSApp.activate(ignoringOtherApps: true)
        observer.map(DistributedNotificationCenter.default().removeObserver)
        timer?.invalidate()
      }
    }

    if #available(macOS 13, *) {
      observer = DistributedNotificationCenter.default().addObserver(
        forName: kTISNotifyEnabledNonKeyboardInputSourcesChanged as NSNotification.Name,
        object: nil,
        queue: nil
      ) { _ in
        checkIfEnabled()
      }
    } else {
      timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
        checkIfEnabled()
      }
    }

    check()
  }

  private func uninstall() {
    isEnabled = false
    observer.map(DistributedNotificationCenter.default().removeObserver)
    timer?.invalidate()

    guard let inputSource = TISInputSource.kaomoji else {
      KPLog("input source not found")
      return
    }

    inputSource.disable()

    do {
      try FileManager.default.removeItem(at: destinationURL)
    } catch {
      KPLog(error.localizedDescription)
    }

    //print(TISInputSource.palettes(includeAllInstalled: true) as NSArray)

    let task = Process()
    task.arguments = ["Kaomoji"]
    task.launchPath = "/usr/bin/killall"
    task.launch()

    check()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

//2023-06-16 09:44:33.300068+0200 Kaomoji Palette[49480:445826] Urgent.  The Input Method local.kaomojipalette.inputmethod.Kaomoji has crashed.  It would be a good idea to stop using it and report the problem.
//2023-06-16 09:44:33.300163+0200 Kaomoji Palette[49480:445826]     Note that this Input Method will no longer be usable in the process: 49480
//2023-06-16 09:44:33.303169+0200 Kaomoji Palette[49480:445826] Urgent.  The Input Method local.kaomojipalette.inputmethod.Kaomoji has crashed.  It would be a good idea to stop using it and report the problem.
//2023-06-16 09:44:33.303258+0200 Kaomoji Palette[49480:445826]     Note that this Input Method will no longer be usable in the process: 49480
//2023-06-16 09:44:33.303444+0200 Kaomoji Palette[49480:445826] Urgent.  The Input Method local.kaomojipalette.inputmethod.Kaomoji has crashed.  It would be a good idea to stop using it and report the problem.
//2023-06-16 09:44:33.303528+0200 Kaomoji Palette[49480:445826]     Note that this Input Method will no longer be usable in the process: 49480
//

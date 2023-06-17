import SwiftUI
import Carbon.HIToolbox

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
    let destinationVersion = destinationInfo["CFBundleVersion"] as? String,
    sourceVersion > destinationVersion
  {
    print(sourceVersion as Any)
    print(destinationVersion as Any)

    return .updateAvailable
  }

  return .installed
}

struct ContentView: View {
  @State private var state = InstallationState.notInstalled
  @State private var isEnabled = TISInputSource.current?.isEnabled == true
  @State private var timer: Timer?
  @State private var observer: NSObjectProtocol?
  private var isInstalled: Bool { state != .notInstalled }
  private var isInstalledAndEnabled: Bool { state != .notInstalled && isEnabled }
//  private var isEnabled: Bool { state != .notInstalled }

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 30) {
        //Image(systemName: "keyboard")
          //.font(.system(size: 52))
        Image(nsImage: NSApp.applicationIconImage)
          .font(.system(size: 44))
          .imageScale(.large)
          .foregroundColor(.accentColor)

        //Text("Indstsillingsassistent til tastatur")
        //Text("Kaomoji Palette Installation Assistant")
        Text("Kaomoji Palette")
          .font(.largeTitle.weight(.semibold))
          .multilineTextAlignment(.center)

        //Text("Din pqrs.org-enhed kan ikke identificeres og kan ikke bruges, før den er identificeret.\n\nHvis tastaturet fungrere korrekt, og der er sluttet en ekstra USB-indtastningsenhed (ikek et tastatur) til computeren, kan du slutte denne app.")

        //Text("Kaomoji Palette is going to install a new input method.\n\nSystem Settings will open and ask you to confirm the installation.")

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

//        if !isInstalled {
//          Button(action: install) { Text("Enable").frame(width: 99) }
//            .keyboardShortcut(.defaultAction)
//        } else {
//          Button(action: uninstall) { Text("Disable").frame(width: 99) }
//        }

        Button(action: !isInstalledAndEnabled ? install : uninstall) {
          Text(!isInstalledAndEnabled ? "Enable" : "Disable").frame(width: 99)
        }
        .keyboardShortcut(
          !isInstalledAndEnabled
          ? .defaultAction
          : KeyboardShortcut(KeyEquivalent(Character(UnicodeScalar(0))))
        )

        Spacer()
      }
      .controlSize(.large)
      .padding()
      .frame(height: 57)
    }
    .navigationTitle("Kaomoji Palette")
    .frame(width: 800 / 1.5, height: 600 / 1.5)
    .onAppear(perform: check)
  }

  private func check() {
    state = installationState
  }

  private func install() {
    do {
      try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    } catch {
      print(error.localizedDescription)
    }

    TISInputSource.register(destinationURL)

    guard let inputSource = TISInputSource.kaomoji else {
      KPLog("input source not found")
      return
    }

    inputSource.enable()

    observer = DistributedNotificationCenter.default().addObserver(
      forName: kTISNotifyEnabledNonKeyboardInputSourcesChanged as NSNotification.Name,
      object: nil,
      queue: nil
    ) { _ in
      if inputSource.isEnabled == true {
        inputSource.select()
        isEnabled = true
        NSApp.activate(ignoringOtherApps: true)
        observer.map(DistributedNotificationCenter.default().removeObserver)
      }
    }

    check()
  }

  private func uninstall() {
    isEnabled = false
    observer.map(DistributedNotificationCenter.default().removeObserver)

    guard let inputSource = TISInputSource.kaomoji else {
      KPLog("input source not found")
      return
    }

    inputSource.disable()

    do {
      try FileManager.default.removeItem(at: destinationURL)
    } catch {
      print(error.localizedDescription)
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

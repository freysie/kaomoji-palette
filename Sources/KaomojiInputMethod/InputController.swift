import AppKit
import InputMethodKit

// TODO: figure out how this is going to work exactly
class InputController: IMKInputController {
  static private(set) var current: InputController?
  static private(set) var currentSession: IMKTextInput?
  static private var isReady = false

  private(set) var currentSession: IMKTextInput?
  private(set) var insertionPointFrame = NSRect.zero

  override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
    super.init(server: server, delegate: delegate, client: inputClient)
    //KPLog("\(#function) \(server as Any) \(delegate as Any) \(inputClient as Any)")
    Self.current = self
  }

  override func activateServer(_ sender: Any!) {
    super.activateServer(sender)

    // On first activation, we will deselect immediately in order to be launched but hidden.
    if !Self.isReady {
      Self.isReady = true
      TISInputSource.kaomoji?.deselect()
      return
    }

    KPLog("\(#function) \(client().bundleIdentifier()!)")
    guard client().bundleIdentifier() != Bundle.main.bundleIdentifier else { return }

    currentSession = client()
    Self.currentSession = client()

    //DispatchQueue.main.async {
    guard AppDelegate.shared.popover?.isShown != true, !AppDelegate.shared.panel.isVisible else { return }
    
    Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
      var rect = NSRect.null
      _ = self.currentSession?.attributes(forCharacterIndex: 0, lineHeightRectangle: &rect)

      //Optional([AnyHashable("NSFont"): ".AppleSystemUIFont 12.00 pt. P [] (0x7fca96b10380) fobj=0x7fca96b10380, spc=3.38", AnyHashable("IMKBaseline"): NSPoint: {0, 1440}, AnyHashable("IMKLineAscent"): 11.60156, AnyHashable("IMKLineHeight"): 15, AnyHashable("IMKTextOrientation"): 1])

      //print(rect)

      self.insertionPointFrame = rect

      AppDelegate.shared.showPickerAtInsertionPoint()
    }

    // TODO: use `client.windowLevel + 1`
  }

  override func deactivateServer(_ sender: Any!) {
    super.deactivateServer(sender)

    KPLog("\(#function) \(client().bundleIdentifier()!)")
  }

  override func hidePalettes() {
    super.hidePalettes()
    KPLog("\(#function)")

    AppDelegate.shared.panel.close()
  }

//  override func menu() -> NSMenu! {
//    KPLog("\(#function) \(super.menu() as Any)")
//
//    let menu = NSMenu()
//    menu.addItem(withTitle: "yeeeeet", action: nil, keyEquivalent: "")
//    return menu
//  }
}

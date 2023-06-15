import AppKit
import InputMethodKit

class InputController: IMKInputController {
  var currentSession: IMKTextInput?

  override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
    super.init(server: server, delegate: delegate, client: inputClient)
    NSLog("[KaomojiPicker] \(#function) \(server as Any) \(delegate as Any) \(inputClient as Any)")
  }

  override func activateServer(_ sender: Any!) {
    super.activateServer(sender)
    NSLog("[KaomojiPicker] \(#function) \(sender as Any)")
    currentSession = client()

    DispatchQueue.main.async {
      var rect = NSRect.null
      print(self.currentSession?.attributes(forCharacterIndex: 0, lineHeightRectangle: &rect) as Any)
      print(rect)

      insertionPointRect = rect
    }
  }

  override class func inputText(_ string: String!, client sender: Any!) -> Bool {
    let result = super.inputText(string, client: client)
    NSLog("[KaomojiPicker] \(#function) \(string as Any) \(sender as Any)")
    return result
  }

  override func hidePalettes() {
    super.hidePalettes()
    NSLog("[KaomojiPicker] \(#function)")
  }
}

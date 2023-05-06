import PreferencePanes
import SwiftUI

class KaomojiPickerPreferencePane: NSPreferencePane {
  override func loadMainView() -> NSView {
    NSHostingView(rootView: KaomojiPickerPreferencePaneView())
  }
}

struct KaomojiPickerPreferencePaneView: View {
  var body: some View {
    Form {
      Text("hullo :3")
      TextField("yeet", text: .constant("aaaaa"))
    }
  }
}

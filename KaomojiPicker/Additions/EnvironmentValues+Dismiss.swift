import SwiftUI

@available(macOS 10.15, *)
extension EnvironmentValues {
  var dismiss: () -> Void {
    { presentationMode.wrappedValue.dismiss() }
  }
}

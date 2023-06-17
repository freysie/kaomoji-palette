import SwiftUI

struct FormToolbar<Content: View>: View {
  var onAdd: () -> ()
  var onRemove: () -> ()
  var canRemove: Bool
  @ViewBuilder var content: Content

  var body: some View {
    HStack(spacing: 0) {
      Button(action: onAdd) {
        Image(systemName: "plus").frame(width: 24, height: 24).offset(x: 1)
      }

      Divider().padding(.bottom, -1)

      Button(action: onRemove) {
        Image(systemName: "minus").frame(width: 24, height: 24)
      }
      .disabled(!canRemove)

      Spacer()

      content
    }
    .overlay(Divider(), alignment: .top)
    .padding(.horizontal, -5)
    .frame(height: 15)
    .buttonStyle(.borderless)
    .font(.system(size: 11, weight: .bold))
    .imageScale(.medium)
  }
}

import SwiftUI

struct KaomojiCategory: Identifiable {
  var id = UUID()
  var title: String
}

struct KaomojiPickerSettingsEditView: View {
  @State private var kaomoji = ""
  @State private var category = "Joy"
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Form {
      TextField("Kaomoji", text: $kaomoji)
      Picker("Category", selection: $category) {
        ForEach(Array(kaomojiSectionTitles.dropFirst()), id: \.self) {
          Text($0).tag($0)
        }
      }
    }
    .frame(width: 300)
    .formStyle(.grouped)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
      ToolbarItem(placement: .confirmationAction) { Button("Add") { dismiss() } }
    }
  }
}

struct KaomojiPickerSettingsView: View {
  @State var isEditSheetPresented = false

  var body: some View {
    VStack {
      GroupBox {
        NSViewControllerPreview {
          KaomojiCollectionViewController(settingsMode: true)
        }
        .frame(height: popoverSize.height)
        .padding(-5)

        HStack(spacing: 0) {
          Button(action: { isEditSheetPresented = true }) { Image(systemName: "plus") }
            .frame(width: 24, height: 24)

          Divider()
            .padding(.vertical, 2)

          Button(action: {}) { Image(systemName: "minus") }
            .frame(width: 24, height: 24)
            .disabled(true)

          Spacer()

          // Button(action: {}) { Image(systemName: "ellipsis.circle") }
          //   .frame(width: 24, height: 24)
        }
        .padding(.horizontal, -5)
        .frame(height: 15)
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 10)
      .zIndex(2)

      Form {
        //TextField("Keyboard Shortcut", text: .constant("⌃⌥⌘Space"))
        LabeledContent("Keyboard Shortcut") { Text("⌃⌥⌘Space") }
        Toggle("Show Favorites", isOn: .constant(true))
        Toggle("Show Recently Used", isOn: .constant(true))
      }
      .formStyle(.grouped)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, -28)
      .scrollDisabled(true)
    }
    .frame(width: 499)
    .sheet(isPresented: $isEditSheetPresented) {
      KaomojiPickerSettingsEditView()
    }
  }
}

#if DEBUG
struct KaomojiPickerSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    KaomojiPickerSettingsView()
  }
}
#endif

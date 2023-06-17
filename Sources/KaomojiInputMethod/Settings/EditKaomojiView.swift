import SwiftUI

struct EditKaomojiView: View {
  @State var kaomoji = Kaomoji(string: "")
  var onCompletion: (Kaomoji) -> ()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      if #available(macOS 13, *) {
        Form {
          TextField("Kaomoji", text: $kaomoji.string)
          Picker("Category", selection: $kaomoji.indexPath.section) {
            ForEach(Array(DataSource.shared.categoryNames.enumerated()), id: \.offset) {
              Text(LocalizedStringKey($0.element))
            }
          }
        }
        .formStyle(.grouped)
      } else {
        Form {
          TextField("Kaomoji:", text: $kaomoji.string)
          Picker("Category:", selection: $kaomoji.indexPath.section) {
            ForEach(Array(DataSource.shared.categoryNames.enumerated()), id: \.offset) {
              Text(LocalizedStringKey($0.element))
            }
          }
        }
        .padding(20)
      }
    }
    .frame(width: 300)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
      ToolbarItem(placement: .confirmationAction) { Button(kaomoji.indexPath.item == -1 ? "Add" : "Done") { submit() } }
    }
  }

  func submit() {
//    DataSource.shared.addKaomoji(string, categoryIndex: categoryIndex)
    //DataSource.shared.editKaomoji(at: indexPath, kaomoji: "", category: "")
//    collectionSelection?.wrappedValue = [IndexPath(item: 0, section: categoryIndex + 1)]
    onCompletion(kaomoji)
    dismiss()
  }
}

struct EditKaomojiView_Previews: PreviewProvider {
  static var previews: some View {
    EditKaomojiView() { _ in }
  }
}

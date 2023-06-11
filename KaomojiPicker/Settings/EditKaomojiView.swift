import SwiftUI

struct EditKaomojiView: View {
  var collectionSelection: Binding<Set<IndexPath>>?
  @State var kaomoji = ""
  @State var category = DataSource.shared.categoryNames.first ?? ""
  @Environment(\.dismiss) private var dismiss

//  init(_ item: Binding<Kaomoji>) {
//    //categories
//    //kaomoji
//  }

  var body: some View {
    Group {
      if #available(macOS 13, *) {
        Form {
          TextField("Kaomoji", text: $kaomoji)
          Picker("Category", selection: $category) {
            ForEach(DataSource.shared.categoryNames, id: \.self) {
              Text(LocalizedStringKey($0)).tag($0)
            }
          }
        }
        .formStyle(.grouped)
      } else {
        Form {
          TextField("Kaomoji:", text: $kaomoji)
          Picker("Category:", selection: $category) {
            ForEach(DataSource.shared.categoryNames, id: \.self) {
              Text(LocalizedStringKey($0)).tag($0)
            }
          }
        }
        .padding(20)
      }
    }
    .frame(width: 300)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
      ToolbarItem(placement: .confirmationAction) { Button("Add") { submit() } }
    }
  }

  func submit() {
    DataSource.shared.addKaomoji(kaomoji, category: category)
    //DataSource.shared.editKaomoji(at: indexPath, kaomoji: "", category: "")
    collectionSelection?.wrappedValue = [IndexPath(item: 0, section: DataSource.shared.index(ofCategory: category) + 1)]
    dismiss()
  }
}

struct EditKaomojiView_Previews: PreviewProvider {
  static var previews: some View {
    EditKaomojiView()
  }
}

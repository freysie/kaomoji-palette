//import SwiftUI
//
//extension String: Identifiable {
//  public var id: Self { self }
//}
//
//struct KaomojiPickerSettingsView: View {
//  @State var data = kaomoji[1]
//  @State var data2 = kaomoji[2]
//  @State var data3 = kaomoji[3]
//  @State var selection = Set<String>()
//
//  var body: some View {
//    VStack {
//      Form {
//        //TextField("Keyboard Shortcut", text: .constant("⌃⇧⌘Space"))
//        LabeledContent("Keyboard Shortcut") { Text("⌃⇧⌘Space") }
//        Toggle("Show Recently Used", isOn: .constant(true))
//      }
//      .formStyle(.grouped)
//      .fixedSize(horizontal: false, vertical: true)
//      .padding(.bottom, -8)
//
//      Grid {
//        GridRow {
//          GroupBox {
//            Table($data, selection: $selection) {
//              TableColumn("[imagine this table header isn't here]") { $value in TextField("", text: $value) }
//              //TableColumn("Category") { _ in TextField("", text: .constant("Joy")) }
//              //TableColumn("Category") { _ in
//              //  Picker("", selection: .constant(1)) {
//              //    Text("Joy").tag(1)
//              //    Text("Love").tag(2)
//              //    Text("Embarrassment").tag(3)
//              //  }
//              //  .pickerStyle(.menu)
//              //}
//            }
//            .tableStyle(.bordered(alternatesRowBackgrounds: false))
//            .padding(-5)
//            .frame(height: 250 / 1.95)
//            .labelsHidden()
//
//            HStack(spacing: 0) {
//              Button(action: { data.append("") }) { Image(systemName: "plus") }
//                .frame(width: 24, height: 24)
//
//              Divider()
//                .padding(.vertical, 2)
//
//              Button(action: {}) { Image(systemName: "minus") }
//                .frame(width: 24, height: 24)
//                .disabled(selection.isEmpty)
//
//              Spacer()
//            }
//            .padding(.horizontal, -5)
//            .frame(height: 15)
//            .buttonStyle(.plain)
//          } label: {
//            Text("Joy")
//              .padding(.vertical, 5)
//              .font(.body)
//          }
//          .padding(.bottom, 10)
//
//          GroupBox {
//            Table($data2, selection: $selection) {
//              TableColumn("[imagine this table header isn't here]") { $value in TextField("", text: $value) }
//              //TableColumn("Category") { _ in TextField("", text: .constant("Joy")) }
//              //TableColumn("Category") { _ in
//              //  Picker("", selection: .constant(1)) {
//              //    Text("Joy").tag(1)
//              //    Text("Love").tag(2)
//              //    Text("Embarrassment").tag(3)
//              //  }
//              //  .pickerStyle(.menu)
//              //}
//            }
//            .tableStyle(.bordered(alternatesRowBackgrounds: false))
//            .padding(-5)
//            .frame(height: 250 / 1.95)
//            .labelsHidden()
//
//            HStack(spacing: 0) {
//              Button(action: { data.append("") }) { Image(systemName: "plus") }
//                .frame(width: 24, height: 24)
//
//              Divider()
//                .padding(.vertical, 2)
//
//              Button(action: {}) { Image(systemName: "minus") }
//                .frame(width: 24, height: 24)
//                .disabled(selection.isEmpty)
//
//              Spacer()
//            }
//            .padding(.horizontal, -5)
//            .frame(height: 15)
//            .buttonStyle(.plain)
//          } label: {
//            Text("Love")
//              .font(.body)
//              .padding(.vertical, 5)
//          }
//          .padding(.bottom, 10)
//        }
//        GridRow {
//          GroupBox {
//            Table($data3, selection: $selection) {
//              TableColumn("[imagine this table header isn't here]") { $value in TextField("", text: $value) }
//              //TableColumn("Category") { _ in TextField("", text: .constant("Joy")) }
//              //TableColumn("Category") { _ in
//              //  Picker("", selection: .constant(1)) {
//              //    Text("Joy").tag(1)
//              //    Text("Love").tag(2)
//              //    Text("Embarrassment").tag(3)
//              //  }
//              //  .pickerStyle(.menu)
//              //}
//            }
//            .tableStyle(.bordered(alternatesRowBackgrounds: false))
//            .padding(-5)
//            .frame(height: 250 / 1.95)
//            .labelsHidden()
//
//            HStack(spacing: 0) {
//              Button(action: { data.append("") }) { Image(systemName: "plus") }
//                .frame(width: 24, height: 24)
//
//              Divider()
//                .padding(.vertical, 2)
//
//              Button(action: {}) { Image(systemName: "minus") }
//                .frame(width: 24, height: 24)
//                .disabled(selection.isEmpty)
//
//              Spacer()
//            }
//            .padding(.horizontal, -5)
//            .frame(height: 15)
//            .buttonStyle(.plain)
//          } label: {
//            Text("Embarrassment")
//              .font(.body)
//              .padding(.vertical, 5)
//          }
//          .padding(.bottom, 20)
//        }
//      }
//      .padding(.horizontal, 20)
//
//    }
//    .frame(width: 499)
//  }
//}
//
//#if DEBUG
//struct KaomojiPickerSettingsView_Previews: PreviewProvider {
//  static var previews: some View {
//    KaomojiPickerSettingsView()
//  }
//}
//#endif
//
////

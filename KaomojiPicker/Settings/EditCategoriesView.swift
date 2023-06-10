import SwiftUI
import Combine

struct EditCategoriesView: View {
  //@State private var categories = DataSource.shared.categories.map { KaomojiCategory(l($0)) }
  @State private var categories = DataSource.shared.categories.map { l($0) }
  //@State private var selection = Set<KaomojiCategory.ID>()
  @State private var selection = IndexSet()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    if #available(macOS 12, *) {
      Form {
        GroupBox {
          CategoriesTable(categories: $categories, selection: $selection)
//          Table($categories, selection: $selection) {
//            TableColumn("Category") { TextField("", text: $0.name).padding(.horizontal, -5) }
//          } rows: {
//            ForEach($categories) { category in
//              TableRow(category)
//                .itemProvider { category.itemProvider }
//            }
//          }
//            .onInsert(of: [Channel.draggableType]) { index, providers in
////              Channel.fromItemProviders(providers) { channels in
////                document.channels.insert(contentsOf: channels, at: newIndex)
////              }
//            }
//          }
          //.tableStyle(.bordered(alternatesRowBackgrounds: false))
//          .tableStyle(.bordered)
          .frame(height: max(1, CGFloat(categories.count)) * 24)
          .padding(-4)
          //.padding(.top, -28)
          //.padding(.bottom, 1)
          //.padding(.bottom, -1)
          //.scrollDisabled(true)

          HStack(spacing: 0) {
            Button(action: { categories.append("") }) {
              Image(systemName: "plus").frame(width: 24, height: 24)
            }

            Divider().padding(.bottom, -1)

            Button(action: deleteSelected) {
              Image(systemName: "minus").frame(width: 24, height: 24)
            }
            .disabled(selection.isEmpty)

            Spacer()
          }
          .overlay(Divider(), alignment: .top)
          .padding(.horizontal, -5)
          .frame(height: 15)
          .buttonStyle(.borderless)
          //.zIndex(2)
        }
      }
      .padding(20)
      .frame(width: 300)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) { Button("Done") { submit() } }
      }
    }
  }

  func submit() {
    //DataSource.shared.categories = categories
    print(categories)
    dismiss()
  }

  func deleteSelected() {
    //selection.sorted().reversed().forEach { categories.remove(at: $0) }
    categories.remove(atOffsets: selection)
    selection = []
  }
}

struct CategoriesTable: NSViewControllerRepresentable {
  @Binding var categories: [String]
  @Binding var selection: IndexSet

  func makeNSViewController(context: Context) -> CategoriesTableViewController {
    let viewController = CategoriesTableViewController(categories: $categories)
    viewController.loadView()

    NotificationCenter.default
      .publisher(for: NSTableView.selectionDidChangeNotification, object: viewController.tableView)
      .sink { _ in DispatchQueue.main.async { selection = viewController.tableView.selectedRowIndexes } }
      .store(in: &context.coordinator.subscriptions)

    return viewController
  }

  func updateNSViewController(_ viewController: CategoriesTableViewController, context: Context) {
    //DispatchQueue.main.async {
      //viewController.tableView.reloadData()
      //viewController.tableView.selectRowIndexes(selection, byExtendingSelection: false)
    //}
  }

  func makeCoordinator() -> Coordinator {
    // Coordinator(parent: self)
    Coordinator()
  }

  class Coordinator: NSObject {
    var subscriptions = Set<AnyCancellable>()

    // let parent: CategoriesTable
    // init(parent: CategoriesTable) {
    //   self.parent = parent
    // }
  }
}

class CategoriesTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  //var categories = [KaomojiCategory]()
  @Binding var categories: [String]

  init(categories: Binding<[String]>) {
    _categories = categories
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private(set) var tableView: NSTableView!
  private(set) var scrollView: NSScrollView!

  private var draggedRowIndexes = IndexSet()

  override func loadView() {
    tableView = NSTableView()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.style = .fullWidth
    tableView.rowHeight = 24
    tableView.allowsMultipleSelection = true
    tableView.usesAlternatingRowBackgroundColors = true
    tableView.focusRingType = .none
    tableView.headerView = nil
    tableView.registerForDraggedTypes([.string])

    let column = NSTableColumn()
    let cell = TextFieldCell()
    cell.focusRingType = .none
    cell.isEditable = true
    column.dataCell = cell
    tableView.addTableColumn(column)

    scrollView = NSScrollView()
    scrollView.documentView = tableView
    scrollView.hasVerticalScroller = true
    scrollView.hasVerticalScroller = true

    view = scrollView
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    categories.count
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    categories[orNil: row]
  }

  func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
    print(object as Any)
    guard let string = object as? String else { return }
    categories[row] = string
  }

  func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
    categories[orNil: row] as? NSString
  }

  func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
    draggedRowIndexes = rowIndexes
  }

  func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
    draggedRowIndexes = []
  }

  func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
    //info.draggingSourceOperationMask

    if dropOperation == .above {
      //info.animatesToDestination = true
      return .move
    } else {
      return []
    }
  }

  func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
    let indexes = draggedRowIndexes.sorted().reversed()

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.3

      tableView.beginUpdates()
      for index in indexes {
        tableView.animator().moveRow(at: index, to: row)
        //categories.move(fromOffsets: [index], toOffset: row)
      }
      tableView.endUpdates()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in 
      for index in indexes {
        categories.move(fromOffsets: [index], toOffset: row)
      }
    }

    return true
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    if let view = tableView.makeView(withIdentifier: .categoriesTableCell, owner: self) {
      return view
    }

    let view = CategoriesTableCellView()
    view.identifier = .categoriesTableCell

    return view
  }
}

extension NSUserInterfaceItemIdentifier {
  static let categoriesTableCell = Self("categoriesTableCell")
}

struct EditCategoriesView_Previews: PreviewProvider {
  static var previews: some View {
    EditCategoriesView()
  }
}

class CategoriesTableCellView: NSTableCellView {
  var field: NSTextField!

  override var objectValue: Any? {
    didSet { field.objectValue = objectValue }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    wantsLayer = true
    autoresizingMask = .width

    field = NSTextField(string: "")
    field.translatesAutoresizingMaskIntoConstraints = false
    //field.lineBreakMode = .byTruncatingMiddle
    //field.usesSingleLineMode = true
    field.isBordered = false
    field.drawsBackground = false
    field.focusRingType = .none
    textField = field
    addSubview(field)

    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
      withVisualFormat: "|-2-[field]-2-|",
      options: .alignAllCenterY,
      metrics: nil,
      views: ["field": field!]
    ) + [
      field.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


//extension String: Identifiable {
//  public var id: Self { self }
//}

//struct KaomojiCategory: Identifiable, Codable {
//  let id = UUID()
//
//  var name: String
//
//  init(_ name: String) {
//    self.name = name
//  }
//}

//extension KaomojiCategory {
//  static var draggableType = UTType(exportedAs: "com.yourCompany.yourApp.channel")
//
//  static func fromItemProviders(_ itemProviders: [NSItemProvider], completion: @escaping ([KaomojiCategory]) -> Void) {
//    let typeIdentifier = Self.draggableType.identifier
//    let filteredProviders = itemProviders.filter {
//      $0.hasItemConformingToTypeIdentifier(typeIdentifier)
//    }
//
//    let group = DispatchGroup()
//    var result = [Int: KaomojiCategory]()
//
//    for (index, provider) in filteredProviders.enumerated() {
//      group.enter()
//      provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { (data, error) in
//        defer { group.leave() }
//        guard let data = data else { return }
//        let decoder = JSONDecoder()
//        guard let channel = try? decoder.decode(KaomojiCategory.self, from: data)
//        else { return }
//        result[index] = channel
//      }
//    }
//
//    group.notify(queue: .global(qos: .userInitiated)) {
//      let channels = result.keys.sorted().compactMap { result[$0] }
//      DispatchQueue.main.async {
//        completion(channels)
//      }
//    }
//  }
//
//  var itemProvider: NSItemProvider {
//    let provider = NSItemProvider()
//    provider.registerDataRepresentation(forTypeIdentifier: Self.draggableType.identifier, visibility: .all) {
//      let encoder = JSONEncoder()
//      do {
//        let data = try encoder.encode(self)
//        $0(data, nil)
//      } catch {
//        $0(nil, error)
//      }
//      return nil
//    }
//    return provider
//  }
//}


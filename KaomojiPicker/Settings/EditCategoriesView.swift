import SwiftUI
import Combine

class EditCategoriesModel: ObservableObject {
  @Published var kaomoji = DataSource.shared.kaomoji
  @Published var categories = DataSource.shared.categories
  @Published var selection = IndexSet()

  let didAdd = PassthroughSubject<Void, Never>()
  let didRemove = PassthroughSubject<IndexSet, Never>()

  func add() {
    var name = l("Untitled Category")
    var counter = 2
    while categories.map(\.name).contains(name) {
      name = l("Untitled Category") + " \(counter)"
      counter += 1
    }

    categories.append(Category(name: name))
    didAdd.send()
  }

  func removeSelected() {
    selection.sorted().reversed().forEach { categories.remove(at: $0) }
    didRemove.send(selection)
    selection = []
  }
}

struct EditCategoriesView: View {
  @StateObject var model = EditCategoriesModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    if #available(macOS 12, *) {
      Form {
        GroupBox {
          CategoriesTable(model: model)
            .frame(height: max(1, CGFloat(max(model.categories.count, 8))) * 24)
            .padding(-4)

          FormToolbar(
            onAdd: model.add,
            onRemove: model.removeSelected,
            canRemove: !model.selection.isEmpty
          ) {
            EmptyView()
          }
        }
      }
      .padding(20)
      .frame(width: 300)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) { Button("Done") { submit() }.keyboardShortcut(.return) }
      }
    }
  }

  func submit() {
    DataSource.shared.setCategories(model.categories.map(\.name), andKaomoji: model.kaomoji)
    dismiss()
  }
}

struct CategoriesTable: NSViewControllerRepresentable {
  @ObservedObject var model: EditCategoriesModel

  func makeNSViewController(context: Context) -> CategoriesTableViewController {
    let viewController = CategoriesTableViewController(model: model)
    viewController.loadView()

    NotificationCenter.default
      .publisher(for: NSTableView.selectionDidChangeNotification, object: viewController.tableView)
      .sink { _ in DispatchQueue.main.async { model.selection = viewController.tableView.selectedRowIndexes } }
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

class CategoriesTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
  @ObservedObject var model: EditCategoriesModel
  private var subscriptions = Set<AnyCancellable>()

  init(model: EditCategoriesModel) {
    self.model = model
    super.init(nibName: nil, bundle: nil)

    model.$selection
      .sink { self.tableView?.selectRowIndexes($0, byExtendingSelection: false) }
      .store(in: &subscriptions)

    model.didAdd
      .sink { [self] in
        let newIndex = tableView.numberOfRows
        model.kaomoji.insert([], at: newIndex)
        tableView.insertRows(at: [newIndex], withAnimation: [])
        tableView.selectRowIndexes([newIndex], byExtendingSelection: false)
        if let rowView = tableView.view(atColumn: 0, row: newIndex, makeIfNecessary: true) as? CategoriesTableCellView {
          view.window?.makeFirstResponder(rowView.field)
        }
      }
      .store(in: &subscriptions)

    model.didRemove
      .sink { [self] in
        tableView.removeRows(at: $0, withAnimation: [])
        model.kaomoji.remove(atOffsets: $0)
      }
      .store(in: &subscriptions)
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
    model.categories.count
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    model.categories[orNil: row].map { l($0.name) }
  }

  //  func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
  //    print(object as Any)
  //    guard let string = object as? String else { return }
  //    model.categories[row].1 = string
  //  }

  func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
    model.categories[orNil: row].map { l($0.name) } as NSString?
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

//    NSAnimationContext.runAnimationGroup { context in
//      context.duration = 0.3

//      tableView.beginUpdates()
      for index in indexes {
        tableView.animator().moveRow(at: index, to: row)
      }
//      tableView.endUpdates()
//    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
      for index in indexes {
        model.kaomoji.move(fromOffsets: [index], toOffset: row)
        model.categories.move(fromOffsets: [index], toOffset: row)
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
    view.field.delegate = self

    return view
  }

  func controlTextDidEndEditing(_ notification: Notification) {
    guard let textField = notification.object as? NSTextField else { return }
    let rowIndex = tableView.row(for: textField)
    guard model.categories.indices.contains(rowIndex) else { return }
    model.categories[rowIndex].name = textField.stringValue
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
    //field.font = .systemFont(ofSize: NSFont.systemFontSize - 1)
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

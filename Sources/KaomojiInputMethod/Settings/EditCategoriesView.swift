import SwiftUI
import Combine

class CategoriesEditingSession: ObservableObject {
  @Published var categories = DataSource.shared.categories
  @Published var kaomoji = DataSource.shared.kaomoji
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

// MARK: -

//struct CategoriesEditView: View {
struct EditCategoriesView: View {
  @StateObject var editingSession = CategoriesEditingSession()
  var onCompletion: ([String], [[String]]) -> ()

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    if #available(macOS 12, *) {
      Form {
        GroupBox {
          CategoriesTable(editingSession: editingSession)
            .frame(height: max(1, CGFloat(max(editingSession.categories.count, 8))) * 24)
            .padding(-4)

          FormToolbar(
            onAdd: editingSession.add,
            onRemove: editingSession.removeSelected,
            canRemove: !editingSession.selection.isEmpty
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
    onCompletion(editingSession.categories.map(\.name), editingSession.kaomoji)
    dismiss()
  }
}

// MARK: -

struct CategoriesTable: NSViewControllerRepresentable {
  @ObservedObject var editingSession: CategoriesEditingSession

  func makeNSViewController(context: Context) -> CategoriesTableViewController {
    CategoriesTableViewController(editingSession: editingSession)
  }

  func updateNSViewController(_ viewController: CategoriesTableViewController, context: Context) {}
}

// TODO: get rid of this and just use CategoriesTable.Coordinator instead? ┐( ´ д ` )┌
class CategoriesTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
  @ObservedObject var editingSession: CategoriesEditingSession
  private var subscriptions = Set<AnyCancellable>()

  init(editingSession: CategoriesEditingSession) {
    self.editingSession = editingSession
    super.init(nibName: nil, bundle: nil)

    editingSession.$selection
      .sink { self.tableView?.selectRowIndexes($0, byExtendingSelection: false) }
      .store(in: &subscriptions)

    editingSession.didAdd
      .sink { [self] in
        let newIndex = tableView.numberOfRows
        editingSession.kaomoji.insert([], at: newIndex)
        tableView.insertRows(at: [newIndex], withAnimation: [])
        tableView.selectRowIndexes([newIndex], byExtendingSelection: false)
        if let rowView = tableView.view(atColumn: 0, row: newIndex, makeIfNecessary: true) as? CategoriesTableCellView {
          view.window?.makeFirstResponder(rowView.field)
        }
      }
      .store(in: &subscriptions)

    editingSession.didRemove
      .sink { [self] in
        tableView.removeRows(at: $0, withAnimation: [])
        editingSession.kaomoji.remove(atOffsets: $0)
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
    tableView.addTableColumn(NSTableColumn())

    scrollView = NSScrollView()
    scrollView.documentView = tableView
    scrollView.hasVerticalScroller = true
    scrollView.hasVerticalScroller = true

    view = scrollView
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    editingSession.categories.count
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    editingSession.categories[orNil: row].map { l($0.name) }
  }

  func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
    editingSession.categories[orNil: row].map { l($0.name) } as NSString?
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
        editingSession.kaomoji.move(fromOffsets: [index], toOffset: row)
        editingSession.categories.move(fromOffsets: [index], toOffset: row)
      }
    }

    return true
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    if let view = tableView.makeView(withIdentifier: .cell, owner: self) {
      return view
    }

    let view = CategoriesTableCellView()
    view.identifier = .cell
    view.field.delegate = self

    return view
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    editingSession.selection = tableView.selectedRowIndexes
  }

  func controlTextDidEndEditing(_ notification: Notification) {
    guard let textField = notification.object as? NSTextField else { return }
    let rowIndex = tableView.row(for: textField)
    guard editingSession.categories.indices.contains(rowIndex) else { return }
    editingSession.categories[rowIndex].name = textField.stringValue
  }
}

// MARK: -

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

// MARK: -

extension NSUserInterfaceItemIdentifier {
  static let cell = Self("cell")
}

// MARK: -

struct EditCategoriesView_Previews: PreviewProvider {
  static var previews: some View {
    EditCategoriesView { _, _ in }
  }
}

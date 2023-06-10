import SwiftUI
import Combine
import UniformTypeIdentifiers

struct KaomojiItem: Identifiable {
  let id = UUID()
  let kaomoji: String
  let categoryIndex: Int
}

// TODO: show confirmation dialog before restoring to defaults
// TODO: make editing categories work on earlier versions of macOS
struct SettingsView: View {
  @State private var selection = Set<IndexPath>()
  @State private var isEditKaomojiSheetPresented = false
  @State private var isEditCategoriesSheetPresented = false
  @State private var isEditCategoriesSheetPresented_ = false
  @State private var editedKaomojiItem: KaomojiItem?
  @State private var isImportSheetPresented = false
  @State private var isExportSheetPresented = false

  private var dataSource: DataSource { .shared }

  var body: some View {
    VStack {
      GroupBox {
        SettingsCollection(selection: $selection, editedKaomojiItem: $editedKaomojiItem)
          //.onDeleteCommand(perform: deleteSelected)
          .frame(minHeight: 178)
          .padding(-5)
          .padding(.bottom, 1)

        HStack(spacing: 0) {
          Button(action: { isEditKaomojiSheetPresented = true }) {
            Image(systemName: "plus").frame(width: 24, height: 24)
          }

          Divider().padding(.bottom, -1)

          Button(action: deleteSelected) {
            Image(systemName: "minus").frame(width: 24, height: 24)
          }
          .disabled(selection.isEmpty)

          Spacer()

          Menu {
            Button("Restore to Defaults") { dataSource.restoreToDefaults() }
            Divider()
            Button("Edit Categories…") { isEditCategoriesSheetPresented = true }
            Divider()
            Button("Import…") { isImportSheetPresented = true }
            Button("Export…") { isExportSheetPresented = true }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
        .overlay(Divider(), alignment: .top)
        .padding(.horizontal, -5)
        .frame(height: 15)
        .buttonStyle(.borderless)
      }
      .overlay(Group {
        if #unavailable(macOS 13) {
          RoundedRectangle(cornerRadius: 5)
            .stroke(.separator, lineWidth: 1)
            .padding(-0.5)
            .offset(y: 24)
            .clipped()
            .offset(y: -24)
        }
      })
      .padding(20)
      .zIndex(2)

      if #available(macOS 13, *) {
        Form {
          LabeledContent("Keyboard Shortcut") { Text("⌃⌥⌘\(l("Space"))") }
          //Toggle("Show Favorites", isOn: .constant(true))
          //Toggle("Show Recently Used", isOn: .constant(true))
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, -38)
        .scrollDisabled(true)
      }
    }
    .frame(width: 499)
    .sheet(item: $editedKaomojiItem) { EditKaomojiView(kaomoji: $0.kaomoji, category: "") }
    .sheet(isPresented: $isEditKaomojiSheetPresented) { EditKaomojiView(collectionSelection: $selection) }
    .sheet(isPresented: $isEditCategoriesSheetPresented) { EditCategoriesView() }
    .fileImporter(isPresented: $isImportSheetPresented, allowedContentTypes: [.propertyList]) {
      switch $0 {
      case .success(let url): importKaomojiSet(at: url)
      case .failure(let error): NSLog(error.localizedDescription)
      }
    }
    .fileExporter(isPresented: $isExportSheetPresented, document: dataSource.kaomojiSet, contentType: .propertyList) {
      switch $0 {
      case .success(let url): NSLog("exported kaomoji set to \(url)")
      case .failure(let error): NSLog(error.localizedDescription)
      }
    }
  }

  private func deleteSelected() {
    // NSApp.sendAction(#selector(SettingsCollectionViewController.deleteSelected), to: nil, from: nil)

    for var indexPath in selection.sorted().reversed() {
      indexPath.section -= 1 /// to account for hidden controls section
      dataSource.removeKaomoji(at: indexPath)
    }

    selection = []
  }

  private func importKaomojiSet(at url: URL) {
    if let importedSet = try? KaomojiSet(contentsOf: url) {
      dataSource.kaomojiSet = importedSet
    }
  }
}

// MARK: -

struct SettingsCollection: NSViewControllerRepresentable {
  @Binding var selection: Set<IndexPath>
  @Binding var editedKaomojiItem: KaomojiItem?

  func makeNSViewController(context: Context) -> SettingsCollectionViewController {
    let viewController = SettingsCollectionViewController(editedKaomojiItem: $editedKaomojiItem)
    viewController.loadView()
    viewController.collectionView.publisher(for: \.selectionIndexPaths)
      .sink { newValue in DispatchQueue.main.async { selection = newValue } }
      .store(in: &context.coordinator.subscriptions)
    return viewController
  }

  func updateNSViewController(_ viewController: SettingsCollectionViewController, context: Context) {
    viewController.collectionView.selectItems(at: selection, scrollPosition: .nearestHorizontalEdge)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator: NSObject {
    var subscriptions = Set<AnyCancellable>()
  }
}

class SettingsCollectionViewController: CollectionViewController {
  override var showsRecents: Bool { false }
  override var usesUppercaseSectionTitles: Bool { false }
  override var selectionColor: NSColor { .controlAccentColor }

  @Binding private var editedKaomojiItem: KaomojiItem?
  private var indexPathsForDraggedItems = Set<IndexPath>()

  init(editedKaomojiItem: Binding<KaomojiItem?>) {
    _editedKaomojiItem = editedKaomojiItem
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    mode = .settings
    showsSearchField = false
    showsCategoryButtons = false

    super.loadView()

    flowLayout.itemSize = NSSize(width: 83, height: 24)
    flowLayout.sectionInset = NSEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    flowLayout.headerReferenceSize = NSSize(width: 80, height: 29)

    collectionView.allowsMultipleSelection = true
    collectionView.backgroundColors = [.textBackgroundColor]

    collectionView.register(
      SettingsCollectionViewSectionHeader.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: .sectionHeader
    )

    collectionView.setDraggingSourceOperationMask([], forLocal: false)
    collectionView.setDraggingSourceOperationMask(.move, forLocal: true)
  }

  // MARK: - Item Click Handling

  @objc override func collectionViewItemWasClicked(_ sender: CollectionViewItem) {
    /// This method intentionally left blank.
  }

  @objc override func collectionViewItemWasDoubleClicked(_ sender: CollectionViewItem) {
    print(#function, sender)
    editedKaomojiItem = KaomojiItem(kaomoji: sender.representedObject as? String ?? "", categoryIndex: 0)
  }

//  override func insertKaomoji(_ sender: NSCollectionViewItem?) {
//    /// This method intentionally left blank.
//  }

  // @objc func editKaomoji(_ sender: NSCollectionViewItem) {}

  //@objc func deleteSelected() {
  //  let indexPaths = collectionView.selectionIndexPaths.sorted().reversed()
  //  indexPaths.forEach(DataSource.shared.removeKaomoji(at:))
  //  collectionView.animator().deleteItems(at: Set(indexPaths))
  //}

  // MARK: - Collection View Delegate

//  override func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
//    /// This method intentionally left blank.
//  }

  // TODO: use pasteboard for reals

  override func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
    //session.draggingFormation = .pile
    indexPathsForDraggedItems = indexPaths
  }

  override func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
    indexPathsForDraggedItems = []
  }

  func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
    if proposedDropOperation.pointee == .on {
      proposedDropOperation.pointee = .before
    }

    return draggingInfo.draggingSourceOperationMask
  }

  // TODO: move kaomoji between sections
  // TODO: correctly move multiple kamoji at once
  func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
    let indexPaths = indexPathsForDraggedItems.sorted().reversed()

    for sourceIndexPath in indexPaths {
      guard sourceIndexPath.section == indexPath.section else { continue }
      collectionView.animator().moveItem(at: sourceIndexPath, to: indexPath)
    }

    /// idk why `NSAnimationContext` with completion handler doesn’t work; instead we use 0.3 sec delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      for var sourceIndexPath in indexPaths {
        guard sourceIndexPath.section == indexPath.section else { continue }
        var indexPath = indexPath
        indexPath.section -= 1 /// to account for hidden controls section
        sourceIndexPath.section -= 1 /// to account for hidden controls section
        DataSource.shared.moveKaomoji(at: sourceIndexPath, to: indexPath)
      }

      //collectionView.selectItems(at: Set(indexPaths), scrollPosition: .nearestHorizontalEdge)
    }

    return true
  }

  // MARK: - Flow Layout Delegate

  override func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
    section == 0 ? .zero : NSSize(width: 80, height: 29)
  }
}

class SettingsCollectionViewSectionHeader: CollectionViewSectionHeader {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    material = .headerView
    blendingMode = .withinWindow

    //titleTextField.textColor = .labelColor
    titleTextField.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

    stackView.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    stackViewTopAnchor.constant = 0

    // let topBorder = NSBox()
    // topBorder.translatesAutoresizingMaskIntoConstraints = false
    // topBorder.boxType = .separator
    // addSubview(topBorder)

    let bottomBorder = NSBox()
    bottomBorder.translatesAutoresizingMaskIntoConstraints = false
    bottomBorder.boxType = .separator
    addSubview(bottomBorder)

    NSLayoutConstraint.activate([
      // topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
      // topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
      // topBorder.topAnchor.constraint(equalTo: topAnchor),

      bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
      bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
      bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: -

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript(orNil index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}

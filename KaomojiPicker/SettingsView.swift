import SwiftUI
import Combine
import UniformTypeIdentifiers

// TODO: show confirmation dialog before restoring to defaults
// TODO: make editing categories work on earlier versions of macOS
struct SettingsView: View {
  @State private var selection = Set<IndexPath>()
  @State private var isEditKaomojiSheetPresented = false
  @State private var isEditCategoriesSheetPresented = false
  @State private var isImportSheetPresented = false
  @State private var isExportSheetPresented = false

  private var dataSource: DataSource { .shared }

  var body: some View {
    VStack {
      GroupBox {
        SettingsCollection(selection: $selection)
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

struct SettingsCollection: NSViewControllerRepresentable {
  @Binding var selection: Set<IndexPath>

  func makeNSViewController(context: Context) -> SettingsCollectionViewController {
    let viewController = SettingsCollectionViewController()
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
    // Coordinator(parent: self)
    Coordinator()
  }

  class Coordinator: NSObject {
    var subscriptions = Set<AnyCancellable>()

    // let parent: SettingsCollection
    // init(parent: SettingsCollection) {
    //   self.parent = parent
    // }
  }
}

class SettingsCollectionViewController: CollectionViewController {
  override var showsRecents: Bool { false }
  override var usesUppercaseSectionTitles: Bool { false }
  override var selectionColor: NSColor { .controlAccentColor }

  private var indexPathsForDraggedItems = Set<IndexPath>()

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

  // MARK: - Actions

  override func insertKaomoji(_ sender: NSCollectionViewItem?) {
    /// This method intentionally left blank.
  }

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

  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
    indexPathsForDraggedItems = indexPaths
  }

  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
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
    section == 0 ? .zero : NSSize(width: 80, height:  29)
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

extension String: Identifiable {
  public var id: Self { self }
}

struct EditCategoriesView: View {
  @State private var categories = DataSource.shared.categories.map { l($0) }
  @State private var selection = Set<String>()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    if #available(macOS 12, *) {
      Form {
        GroupBox {
          Table($categories, selection: $selection) {
            TableColumn("Category") { TextField("", text: $0).padding(.horizontal, -5) }
          }
          //.tableStyle(.bordered(alternatesRowBackgrounds: false))
          .tableStyle(.bordered)
          .padding(-5)
          .frame(height: 20 + max(1, CGFloat(categories.count)) * 24)
          //.padding(.bottom, -1)

          HStack(spacing: 0) {
            Button(action: { categories.append("") }) { Image(systemName: "plus") }
              .frame(width: 24, height: 24)

            Divider()
              .padding(.bottom, -1)

            Button(action: deleteSelected) { Image(systemName: "minus") }
              .frame(width: 24, height: 24)
              .disabled(selection.isEmpty)

            Spacer()
          }
          //.overlay(alignment: .top) { Divider() }
          .padding(.horizontal, -5)
          .frame(height: 15)
          .buttonStyle(.borderless)
        }
      }
      .padding(20)
      .frame(width: 300)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
      }
    }
  }

  func deleteSelected() {
    for category in selection.reversed() {
      categories.removeAll { $0 == category }
    }

    selection = []
  }
}

struct EditKaomojiView: View {
  @Binding var collectionSelection: Set<IndexPath>
  @State private var kaomoji = ""
  @State private var category = DataSource.shared.categories.first ?? ""
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      if #available(macOS 13, *) {
        Form {
          TextField("Kaomoji", text: $kaomoji)
          Picker("Category", selection: $category) {
            ForEach(DataSource.shared.categories, id: \.self) {
              Text(LocalizedStringKey($0)).tag($0)
            }
          }
        }
        .formStyle(.grouped)
      } else {
        Form {
          TextField("Kaomoji:", text: $kaomoji)
          Picker("Category:", selection: $category) {
            ForEach(DataSource.shared.categories, id: \.self) {
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
    collectionSelection = [IndexPath(item: 0, section: DataSource.shared.index(ofCategory: category))]
    dismiss()
  }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
struct EditKaomojiView_Previews: PreviewProvider {
  static var previews: some View {
    EditKaomojiView(collectionSelection: .constant([]))
  }
}
struct EditCategoriesView_Previews: PreviewProvider {
  static var previews: some View {
    EditCategoriesView()
  }
}
#endif

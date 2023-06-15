import SwiftUI
import Combine
import UniformTypeIdentifiers
import KeyboardShortcuts

struct SettingsView: View {
  @State private var selection = Set<IndexPath>()
  @State private var editedKaomoji: Kaomoji?
  @State private var isAddSheetPresented = false
  @State private var isCategoriesSheetPresented = false
  @State private var isImportSheetPresented = false
  @State private var isExportSheetPresented = false

  private var dataSource: DataSource { .shared }

  var body: some View {
    VStack {
      GroupBox {
        SettingsCollection(selection: $selection, editedKaomoji: $editedKaomoji)
          .frame(minHeight: 178)
          .padding(-5)
          .padding(.bottom, 1)

        FormToolbar(
          onAdd: { isAddSheetPresented = true },
          onRemove: { deleteSelected() },
          canRemove: !selection.isEmpty
        ) {
          Menu {
            Button("Edit Categories…") { isCategoriesSheetPresented = true }
            Divider()
            Button("Import…") { isImportSheetPresented = true }
            Button("Export…") { isExportSheetPresented = true }
            Divider()
            Button("Clear Recently Used Kaomoji") { dataSource.clearRecents() }
            Button("Restore to Defaults") { restoreToDefaults() }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
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
//          LabeledContent("Keyboard Shortcut") {
//            //Text("⌃⌥⌘\(l("Space"))")
//            KeyboardShortcuts.Recorder(for: .showPalette)
//          }
          KeyboardShortcuts.Recorder(l("Keyboard Shortcut"), name: .showPalette)

          //Toggle("Show Favorites", isOn: .constant(true))
          //Toggle("Show Recently Used", isOn: .constant(true))
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, -38)
      } else {
        Form {
          KeyboardShortcuts.Recorder(l("Keyboard Shortcut:"), name: .showPalette)

          //Toggle("Show Favorites", isOn: .constant(true))
          //Toggle("Show Recently Used", isOn: .constant(true))
        }
        .padding(.horizontal, 20)
        .padding(.top, -10)
        .padding(.bottom, 20)
      }
    }
    .frame(width: 499)
    .sheet(item: $editedKaomoji) { kaomoji in
      EditKaomojiView(kaomoji: kaomoji) { newKaomoji in
        dataSource.updateKaomoji(at: kaomoji.indexPath, string: newKaomoji.string)

        if kaomoji.indexPath.section != newKaomoji.indexPath.section {
          dataSource.moveKaomoji(at: kaomoji.indexPath, to: IndexPath(item: 0, section: newKaomoji.indexPath.section))
          selection = [IndexPath(item: 0, section: newKaomoji.indexPath.section + 1)]
        } else {
          selection = [IndexPath(item: newKaomoji.indexPath.item, section: newKaomoji.indexPath.section + 1)]
        }
      }
    }
    .sheet(isPresented: $isAddSheetPresented) {
      EditKaomojiView() { newKaomoji in
        dataSource.addKaomoji(newKaomoji.string, categoryIndex: newKaomoji.indexPath.section)
        selection = [IndexPath(item: 0, section: newKaomoji.indexPath.section + 1)]
      }
    }
    .sheet(isPresented: $isCategoriesSheetPresented) { EditCategoriesView() }
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

  private func restoreToDefaults() {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = l("Are you sure you want to restore kaomoji to defaults?")
    //alert.informativeText = l("This action cannot be undone and all your kaomoji will be lost unless you have exported them first.")
    alert.addButton(withTitle: l("Restore")).hasDestructiveAction = true
    alert.addButton(withTitle: l("Cancel"))
    alert.beginSheetModal(for: AppDelegate.shared.settingsWindow) {
      if $0 == .alertFirstButtonReturn {
        dataSource.restoreToDefaults()
      }
    }
  }
}

// MARK: -

struct SettingsCollection: NSViewControllerRepresentable {
  @Binding var selection: Set<IndexPath>
  @Binding var editedKaomoji: Kaomoji?

  func makeNSViewController(context: Context) -> SettingsCollectionViewController {
    let viewController = SettingsCollectionViewController(editedKaomoji: $editedKaomoji)
    viewController.loadView()
    viewController.collectionView.publisher(for: \.selectionIndexPaths)
      .sink { newValue in DispatchQueue.main.async { selection = newValue } }
      .store(in: &context.coordinator.subscriptions)
    return viewController
  }

  func updateNSViewController(_ viewController: SettingsCollectionViewController, context: Context) {
    //viewController.collectionView.selectionIndexPaths = selection
    DispatchQueue.main.async {
      viewController.collectionView.selectItems(at: selection, scrollPosition: .nearestHorizontalEdge)
    }
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

  @Binding private var editedKaomoji: Kaomoji?
  private var indexPathsForDraggedItems = Set<IndexPath>()

  init(editedKaomoji: Binding<Kaomoji?>) {
    _editedKaomoji = editedKaomoji
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    collectionStyle = .settings
    showsSearchField = false
    showsCategoryButtons = false

    super.loadView()

    flowLayout.itemSize = NSSize(width: 83, height: 24)
    flowLayout.sectionInset = NSEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    flowLayout.headerReferenceSize = NSSize(width: 80, height: 29)

    collectionView.mouseDownCanMovePopover = false
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
    guard let indexPath = collectionView.indexPath(for: sender) else { return }
    collectionView.selectionIndexPaths = [indexPath]
    editedKaomoji = Kaomoji(
      string: sender.representedObject as? String ?? "",
      indexPath: IndexPath(item: indexPath.item, section: indexPath.section)
    )
  }

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

    // let topBorder = NSBox()
    // topBorder.translatesAutoresizingMaskIntoConstraints = false
    // topBorder.boxType = .separator
    // addSubview(topBorder)

    let bottomBorder = NSBox()
    bottomBorder.translatesAutoresizingMaskIntoConstraints = false
    bottomBorder.boxType = .separator
    addSubview(bottomBorder)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 1.5),
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

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}

struct SettingsCollectionViewSectionHeader_Previews: PreviewProvider {
  static var previews: some View {
    NSViewPreview {
      let header = SettingsCollectionViewSectionHeader()
      header.titleTextField.stringValue = l("Joy")
      NSLayoutConstraint.activate([
        header.widthAnchor.constraint(equalToConstant: popoverSize.width),
        header.heightAnchor.constraint(equalToConstant: 29),
      ])
      return header
    }
    .previewLayout(.sizeThatFits)
  }
}

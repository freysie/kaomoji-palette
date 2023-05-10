import SwiftUI
import Combine

struct SettingsView: View {
  @State private var selection = Set<IndexPath>()
  @State private var isEditSheetPresented = false

  var body: some View {
    VStack {
      GroupBox {
        SettingsCollection(selection: $selection)
          //.onDeleteCommand(perform: deleteSelected)
          .frame(height: 621)
          .padding(-5)
          .padding(.bottom, 1)

        HStack(spacing: 0) {
          Button(action: { isEditSheetPresented = true }) { Image(systemName: "plus") }
            .frame(width: 24, height: 24)

          Divider()
            .padding(.bottom, -1)

          Button(action: { deleteSelected() }) { Image(systemName: "minus") }
            .frame(width: 24, height: 24)
            .disabled(selection.isEmpty)

//          Divider()
//            .padding(.bottom, -1)
//
//          Menu {
//            Button("Reset to Defaults") {}
//            Divider()
//            Button("Export…") {}
//            Button("Improt…") {}
//          } label: {
//            Image(systemName: "ellipsis.circle")
//          }
//          .frame(width: 24, height: 24)

          Spacer()
        }
        .overlay(alignment: .top) { Divider() }
        //.overlay(alignment: .top) { Rectangle().fill(Color(NSColor.separatorColor)).frame(height: 1) }
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
        //Toggle("Show Favorites", isOn: .constant(true))
        //Toggle("Show Recently Used", isOn: .constant(true))
      }
      .formStyle(.grouped)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, -28)
      .scrollDisabled(true)
    }
    .frame(width: 499)
    .sheet(isPresented: $isEditSheetPresented) {
      SettingsEditView(collectionSelection: $selection)
    }
  }

  func deleteSelected() {
    for indexPath in selection.sorted().reversed() {
      DataSource.shared.removeKaomoji(at: indexPath)
    }

    selection = []
  }
}

//struct KaomojiCategory: Identifiable {
//  var id = UUID()
//  var title: String
//}

struct SettingsCollection: NSViewControllerRepresentable {
  @Binding var selection: Set<IndexPath>
  //@State var isChangingSelection = false

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
  private var indexPathsForDraggedItems = Set<IndexPath>()
  private var subscriptions = Set<AnyCancellable>()

  override func loadView() {
    showsRecents = false
    showsSearchField = false
    usesUppercaseSectionTitles = false

    selectionColor = .controlAccentColor

    super.loadView()

    flowLayout.sectionInset = NSEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    collectionView.allowsMultipleSelection = true

    collectionView.register(
      SettingsCollectionViewSectionHeader.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: .sectionHeader
    )

    //collectionView.registerForDraggedTypes([.item])
    collectionView.setDraggingSourceOperationMask([], forLocal: false)
    collectionView.setDraggingSourceOperationMask(.move, forLocal: true)

    DataSource.shared.objectWillChange.sink { self.collectionView.reloadData() }.store(in: &subscriptions)
  }

  // MARK: - Actions

  override func cancelOperation(_ sender: Any?) {
    /// This method intentionally left blank.
  }

  // MARK: - Collection View Delegate

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

  func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
    for sourceIndexPath in indexPathsForDraggedItems.sorted().reversed() {
      collectionView.animator().moveItem(at: sourceIndexPath, to: indexPath)
    }

    /// idk why NSAnimationContext with completion handler doesn’t work; instead we use 0.3 sec delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
      for sourceIndexPath in indexPathsForDraggedItems.sorted().reversed() {
        DataSource.shared.moveKaomoji(at: sourceIndexPath, to: indexPath)
      }
    }

    return true
  }
}

class SettingsCollectionViewSectionHeader: CollectionViewSectionHeader {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    //material = .underWindowBackground
    //material = .contentBackground
    material = .headerView
    blendingMode = .withinWindow

    titleTextField.textColor = .labelColor

    stackView.edgeInsets = NSEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
    stackView.layer?.sublayerTransform = CATransform3DIdentity
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

struct SettingsEditView: View {
  @Binding var collectionSelection: Set<IndexPath>
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
struct KaomojiPickerSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
#endif

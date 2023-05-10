import AppKit
//import UniformTypeIdentifiers

class CollectionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
//  let settingsMode: Bool

  var showsRecents = true
  var showsSearchField = true
  var usesUppercaseSectionTitles = true

  var selectionColor = NSColor.controlAccentColor.withAlphaComponent(0.25)

  private(set) var flowLayout: NSCollectionViewFlowLayout!
  private(set) var collectionView: NSCollectionView!

  private let dataSource = DataSource.shared

  private var kaomoji: [[String]] { (showsRecents ? [dataSource.recents] : []) + dataSource.kaomoji }
  private var categories: [String] { (showsRecents ? [l("Recently Used")] : []) + dataSource.categories }

//  init(settingsMode: Bool = false) {
//    self.settingsMode = settingsMode
//    super.init(nibName: nil, bundle: nil)
//
//    if settingsMode {
//      _kaomoji = Array(_kaomoji.dropFirst())
//      _kaomojiSectionTitles = Array(_kaomojiSectionTitles.dropFirst())
//    }
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }

  override func loadView() {
    flowLayout = NSCollectionViewFlowLayout()
    flowLayout.itemSize = NSSize(width: 83, height: 24)
    flowLayout.sectionInset = NSEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.minimumLineSpacing = 2
    flowLayout.headerReferenceSize = NSSize(width: 80, height: 27)
    flowLayout.sectionHeadersPinToVisibleBounds = true

    collectionView = NSCollectionView()
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.isSelectable = true
    collectionView.backgroundColors = [.clear]
    collectionView.collectionViewLayout = flowLayout
    collectionView.focusRingType = .default

    collectionView.register(
      CollectionViewItem.self,
      forItemWithIdentifier: .item
    )

    collectionView.register(
      CollectionViewSectionHeader.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: .sectionHeader
    )

    collectionView.registerForDraggedTypes([.string])
    collectionView.setDraggingSourceOperationMask(.copy, forLocal: false)

    let scrollView = NSScrollView()
    scrollView.autoresizingMask = [.width, .height]
    scrollView.hasVerticalScroller = true
    scrollView.documentView = collectionView

    if showsSearchField {
      let searchField = NSSearchField()

      let settingsButton = NSButton()
      settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!
      settingsButton.target = NSApp.delegate
      settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
      settingsButton.isBordered = false

      let controlsStackView = NSStackView(views: [searchField, settingsButton])
      controlsStackView.edgeInsets = NSEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
      controlsStackView.spacing = 6

      let stackView = NSStackView(views: [scrollView, BorderView(), controlsStackView])
      stackView.autoresizingMask = [.width, .height]
      stackView.translatesAutoresizingMaskIntoConstraints = true
      stackView.orientation = .vertical
      stackView.spacing = 0

      NSLayoutConstraint.activate([
        settingsButton.widthAnchor.constraint(equalToConstant: 26),
        controlsStackView.heightAnchor.constraint(equalToConstant: 37),
      ])

      view = stackView
    } else {
      view = scrollView
    }
  }

  private class BorderView: NSView {
    override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: 1) }
    override var allowsVibrancy: Bool { true }
    override func draw(_ dirtyRect: NSRect) { NSColor.separatorColor.setFill(); bounds.fill() }
  }

  // MARK: - Actions

  override func cancelOperation(_ sender: Any?) {
    view.window?.close()
  }

  // MARK: - Collection View Data Source

  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    kaomoji.count
  }

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    kaomoji[section].count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    //let item = collectionView.makeItem(withIdentifier: .item, for: indexPath) as! CollectionViewItem
    let item = CollectionViewItem()
    item.loadView()
    //item.settingsMode = settingsMode
    item.selectionColor = selectionColor
    item.textField?.stringValue = kaomoji[indexPath.section][indexPath.item]
    return item
  }

  func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
    switch kind {
    case NSCollectionView.elementKindSectionHeader:
      let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .sectionHeader, for: indexPath) as! CollectionViewSectionHeader

      headerView.titleTextField.stringValue = usesUppercaseSectionTitles
      ? categories[indexPath.section].localizedUppercase
      : categories[indexPath.section]

      if indexPath.section == 0, !showsSearchField, !(headerView is SettingsCollectionViewSectionHeader) {
        let settingsButton = NSButton()
        settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!
        settingsButton.target = NSApp.delegate
        settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
        settingsButton.isBordered = false

        headerView.stackView.addArrangedSubview(NSView())
        headerView.stackView.addArrangedSubview(settingsButton)
      }

      return headerView

    case NSCollectionView.elementKindInterItemGapIndicator:
      let indicator = NSView()
      indicator.wantsLayer = true
      indicator.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
      indicator.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        indicator.widthAnchor.constraint(equalToConstant: 3),
        indicator.heightAnchor.constraint(equalToConstant: 24),
      ])
      return indicator
      //return collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .interGapIndicator, for: indexPath)
      //return collectionView.supplementaryView(forElementKind: kind, at: indexPath) ?? NSView()

    default:
      return NSView()
    }
  }

  // MARK: - Collection View Delegate

  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
    //guard !settingsMode else { return nil }
    kaomoji[indexPath.section][indexPath.item] as NSString
//    let pasteboardItem = NSPasteboardItem()
//    pasteboardItem.setString(kaomoji[indexPath.section][indexPath.item], forType: .string)
////    if settingsMode {
////      pasteboardItem.setData(Data(), forType: .item)
////    }
//    return pasteboardItem
  }
}

// MARK: -

#if DEBUG
import SwiftUI
struct CollectionViewController_Previews: PreviewProvider {
  static var previews: some View {
    NSViewControllerPreview {
      CollectionViewController()
    }
    .frame(width: popoverSize.width, height: popoverSize.height)
  }
}
#endif

//extension NSTableView {
//  var headerView: NSTableHeaderView? { get { nil } set {} }
//}

//class KaomojiCollectionView: NSCollectionView {
//  override func supplementaryView(forElementKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? {
//    print(#function, elementKind)
//    if elementKind == "NSCollectionElementKindSelectionRectIndicator" {
//      return nil
//    } else {
//      return super.supplementaryView(forElementKind: elementKind, at: indexPath)
//    }
//  }
//}

extension NSUserInterfaceItemIdentifier {
  static let item = Self("item")
  static let sectionHeader = Self("sectionHeader")
  //static let interGapIndicator = Self("interGapIndicator")
}

//extension NSPasteboard.PasteboardType {
//  static let item = Self(UTType.item.identifier)
//}

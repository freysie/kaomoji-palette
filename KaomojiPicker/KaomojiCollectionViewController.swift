import AppKit

class KaomojiCollectionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
  let settingsMode: Bool

  var _kaomoji = kaomoji
  var _kaomojiSectionTitles = kaomojiSectionTitles

  var collectionView: NSCollectionView!

  init(settingsMode: Bool = false) {
    self.settingsMode = settingsMode
    super.init(nibName: nil, bundle: nil)

    if settingsMode {
      _kaomoji = Array(_kaomoji.dropFirst())
      _kaomojiSectionTitles = Array(_kaomojiSectionTitles.dropFirst())
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let flowLayout = NSCollectionViewFlowLayout()
    flowLayout.itemSize = NSSize(width: 80, height: 24)
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

    if settingsMode {
      collectionView.allowsMultipleSelection = true
    }

    collectionView.register(
      KaomojiCollectionViewSectionHeader.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: NSUserInterfaceItemIdentifier("header")
    )

    collectionView.registerForDraggedTypes([.string])

    let searchField = NSSearchField()

    let settingsButton = NSButton(
      image: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!,
      target: NSApp.delegate,
      action: #selector(AppDelegate.showSettingsWindow(_:))
    )

    let controlsStackView = NSStackView(views: [searchField, settingsButton])
    controlsStackView.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 5, right: 10)

    // let stackView = NSStackView(views: [headerStackView, collectionView])
    // stackView.autoresizingMask = [.width, .height]
    // stackView.translatesAutoresizingMaskIntoConstraints = true
    // stackView.orientation = .vertical
    // stackView.spacing = 0

    let scrollView = NSScrollView()
    scrollView.autoresizingMask = [.width, .height]
    scrollView.hasVerticalScroller = true
    //scrollView.documentView = stackView
    scrollView.documentView = collectionView
    //scrollView.additionalSafeAreaInsets = .init(top: 30, left: 0, bottom: 0, right: 0)
    scrollView.drawsBackground = false
    //scrollView.findBarView = stackView
    //scrollView.isFindBarVisible = true

    var stackedViews = [scrollView, BorderView()]
    if !settingsMode { stackedViews.append(controlsStackView) }
    let stackView = NSStackView(views: stackedViews)
    stackView.autoresizingMask = [.width, .height]
    stackView.translatesAutoresizingMaskIntoConstraints = true
    stackView.orientation = .vertical
    stackView.spacing = 0

    if settingsMode {
      view = stackView
    } else {
      view = scrollView
    }

    // NSLayoutConstraint.activate([
    //   stackView.widthAnchor.constraint(equalToConstant: popoverSize.width),
    //   stackView.heightAnchor.constraint(equalToConstant: popoverSize.height),
    //   controlsStackView.heightAnchor.constraint(equalToConstant: 37),
    // ])
  }

  //override var preferredMinimumSize: NSSize { popoverSize }
  //override var preferredContentSize: NSSize { get { popoverSize } set {} }

  class BorderView: NSView {
    override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: 1) }
    override var allowsVibrancy: Bool { true }
    override func draw(_ dirtyRect: NSRect) { NSColor.separatorColor.setFill(); bounds.fill() }
  }

  override func cancelOperation(_ sender: Any?) {
    guard !settingsMode else { return }
    view.window?.close()
  }

  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    _kaomoji.count
  }

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    _kaomoji[section].count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = KaomojiCollectionViewItem()
    item.loadView()
    item.settingsMode = settingsMode
    item.textField?.stringValue = _kaomoji[indexPath.section][indexPath.item]
    return item
  }

  func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
    let headerView = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier("header"), for: indexPath) as! KaomojiCollectionViewSectionHeader

    headerView.titleTextField.stringValue = _kaomojiSectionTitles[indexPath.section].localizedUppercase

    if settingsMode {
      headerView.material = .underWindowBackground
      headerView.blendingMode = .withinWindow
      headerView.titleTextField.stringValue = _kaomojiSectionTitles[indexPath.section]
      headerView.titleTextField.textColor = .labelColor
      headerView.stackView.edgeInsets = NSEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
      //headerView.leadingAnchorConstraint.constant = 10
      //headerView.trailingAnchorConstraint.constant = -10
      //headerView.topAnchorConstraint.constant = 5
      headerView.stackView.layer?.sublayerTransform = CATransform3DIdentity
    } else if indexPath.section == 0 {
      let settingsButton = NSButton()
      settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!
      settingsButton.target = NSApp.delegate
      settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
      settingsButton.isBordered = false

      headerView.stackView.addArrangedSubview(NSView())
      headerView.stackView.addArrangedSubview(settingsButton)
    }

    return headerView
  }

  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
    guard !settingsMode else { return nil }
    //kaomoji[indexPath.section][indexPath.item] as NSString
    let pasteboardItem = NSPasteboardItem()
    pasteboardItem.setString(_kaomoji[indexPath.section][indexPath.item], forType: .string)
    return pasteboardItem
  }
}

#if DEBUG
import SwiftUI
struct KaomojiPickerViewController_Previews: PreviewProvider {
  static var previews: some View {
    NSViewControllerPreview {
      KaomojiCollectionViewController()
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

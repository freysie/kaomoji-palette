import AppKit
import Combine

class CollectionView: NSCollectionView {
//  override var mouseDownCanMoveWindow: Bool { true }
}

//class BaseCollectionViewController: NSViewController {}
//class PickerCollectionViewController: BaseCollectionViewController {}
//class PopoverCollectionViewController: PickerCollectionViewController {}
//class PanelCollectionViewController: PickerCollectionViewController {}
//class SettingslCollectionViewController: BaseCollectionViewController {}

class CollectionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, NSSearchFieldDelegate, NSControlTextEditingDelegate {
  private static let recentsCategoryTitle = ".:☆*:･"
  // private static let recentsCategoryTitle = "。.:☆*:･"

  enum Mode { case pickerPopover, pickerWindow, settings }
  var mode = Mode.pickerPopover

  var showsRecents: Bool { !dataSource.recents.isEmpty }
  //var showsSearchField: Bool { false }
  var showsSearchField = true
  var showsCategoryButtons = true
  var usesMaterialBackground = false
  var usesUppercaseSectionTitles: Bool { true }
  var selectionColor: NSColor { .controlAccentColor.withAlphaComponent(0.25) }
  //var selectionColor: NSColor { .controlAccentColor.withSystemEffect(.disabled) }

  private(set) var flowLayout: NSCollectionViewFlowLayout!
  private(set) var collectionView: NSCollectionView!
  private(set) var scrollView: NSScrollView!
  private(set) var stackView: NSStackView!
  private(set) var closeButton: NSButton?
  private(set) var categoryButtons = [CategoryButton]()
  private(set) var categoryScrollView: NSScrollView!
  private(set) var placeholderView: NSTextField!
  private(set) weak var searchField: NSSearchField?

  private var currentSectionIndex = 0
  private var isSearching = false
  private var searchResults = [String]()

  private var appDelegate: AppDelegate { .shared }
  private var dataSource: DataSource { .shared }
  private var subscriptions = Set<AnyCancellable>()

  private var kaomoji: [[String]] { (showsRecents ? [dataSource.recents] : []) + dataSource.kaomoji }
  private var categories: [String] { (showsRecents ? [l("Recently Used")] : []) + dataSource.categories }

  override func loadView() {
    // TODO: tweak spacing
    flowLayout = NSCollectionViewFlowLayout()
    //flowLayout.itemSize = NSSize(width: 76, height: 24)
    //flowLayout.itemSize = NSSize(width: 83, height: 24)
    flowLayout.itemSize = NSSize(width: 100, height: 24)
    flowLayout.sectionInset = NSEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)

    flowLayout.minimumInteritemSpacing = 3
    flowLayout.minimumLineSpacing = 3
    //flowLayout.headerReferenceSize = NSSize(width: 80, height: 26)
    flowLayout.sectionHeadersPinToVisibleBounds = true

    collectionView = CollectionView()
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.isSelectable = true
    collectionView.backgroundColors = [.clear]
    collectionView.collectionViewLayout = flowLayout

    collectionView.register(
      CollectionViewItem.self,
      forItemWithIdentifier: .item
    )

    collectionView.register(
      CollectionViewSectionHeader.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: .sectionHeader
    )

    collectionView.register(
      CollectionViewControlsHeader.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: .controlsHeader
    )

    collectionView.registerForDraggedTypes([.string])
    collectionView.setDraggingSourceOperationMask(.copy, forLocal: false)

    scrollView = NSScrollView()
    scrollView.autoresizingMask = [.width, .height]
    scrollView.hasVerticalScroller = true
    scrollView.documentView = collectionView
    scrollView.contentView.postsBoundsChangedNotifications = true

    if showsCategoryButtons {
      for (index, category) in categories.enumerated() {
        let title = showsRecents && index == 0 ? Self.recentsCategoryTitle : kaomoji[index].first ?? ""
        let button = CategoryButton(radioButtonWithTitle: title, target: self, action: #selector(jumpTo(_:)))
        button.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .bold)
        button.toolTip = l(category)
        button.isBordered = false
        button.imagePosition = .noImage
        button.tag = index + 1
        categoryButtons.append(button)
      }

      categoryButtons.first?.state = .on

      let categoryStackView = NSStackView(views: categoryButtons)
      categoryStackView.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
      categoryStackView.spacing = 7

      categoryScrollView = NSScrollView()
      categoryScrollView.documentView = categoryStackView
      categoryScrollView.drawsBackground = false
      categoryScrollView.verticalScrollElasticity = .none
      //categoryScrollView.hasHorizontalScroller = true
      //categoryScrollView.horizontalScroller?.controlSize = .mini

      let border = NSBox()
      border.translatesAutoresizingMaskIntoConstraints = false
      border.boxType = .separator

      stackView = NSStackView(views: [scrollView, border, categoryScrollView])

      categoryStackView.wantsLayer = true
      categoryStackView.layer?.sublayerTransform = CATransform3DMakeTranslation(0, 1, 0)
      //categoryStackView.layer?.borderColor = NSColor.systemMint.cgColor
      //categoryStackView.layer?.borderWidth = 1

      NSLayoutConstraint.activate([
        //categoryStackView.heightAnchor.constraint(equalToConstant: 38),
        categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor),
        categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.topAnchor),
        categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
        categoryScrollView.heightAnchor.constraint(equalToConstant: 38),
      ])
    } else {
      stackView = NSStackView(views: [scrollView])
    }

    if mode == .pickerWindow {
      // TODO: get better icon
      let closeButton = NSButton()
      closeButton.image = .closeIcon
      closeButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13.5, weight: .heavy)
      closeButton.action = #selector(NSWindow.close)
      closeButton.isBordered = false
      self.closeButton = closeButton

      let settingsButton = NSButton()
      settingsButton.image = .settingsIcon
      settingsButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13.5, weight: .regular)
      settingsButton.target = NSApp.delegate
      settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
      settingsButton.isBordered = false
      settingsButton.focusRingType = .none

      let titlebarStackView = NSStackView(views: [closeButton, NSView(), settingsButton])
      //titlebarStackView.edgeInsets = NSEdgeInsets(top: 0, left: 7, bottom: 0, right: 11)
      titlebarStackView.edgeInsets = NSEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)

      NSLayoutConstraint.activate([
        closeButton.widthAnchor.constraint(equalToConstant: 14),
        closeButton.heightAnchor.constraint(equalToConstant: 14),
        settingsButton.widthAnchor.constraint(equalToConstant: 14),
        settingsButton.widthAnchor.constraint(equalToConstant: 14),
        titlebarStackView.heightAnchor.constraint(equalToConstant: 27),
      ])

      stackView.insertArrangedSubview(titlebarStackView, at: 0)
    }

    placeholderView = NSTextField(labelWithString: l("No Kaomoji Found"))
    placeholderView.translatesAutoresizingMaskIntoConstraints = false
    placeholderView.textColor = .secondaryLabelColor
    placeholderView.isHidden = true
    stackView.addSubview(placeholderView)

    NSLayoutConstraint.activate([
      placeholderView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
      placeholderView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: 33/2),
    ])

    stackView.autoresizingMask = [.width, .height]
    stackView.translatesAutoresizingMaskIntoConstraints = true
    stackView.orientation = .vertical
    stackView.spacing = 0

    if usesMaterialBackground {
      let effectView = NSVisualEffectView()
      effectView.autoresizingMask = [.width, .height]
      effectView.blendingMode = .behindWindow
      effectView.material = .popover
      effectView.maskImage = .cornerMask(radius: 11)
      effectView.addSubview(stackView)

      view = effectView
    } else {
      view = stackView
    }

    //if mode != .settings {
    DataSource.shared.$categories.sink { _ in self.collectionView.reloadData() }.store(in: &subscriptions)
    DataSource.shared.$kaomoji.sink { _ in self.collectionView.reloadData() }.store(in: &subscriptions)
    //}

    if mode != .settings {
      NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        .sink { _ in self.scrollViewDidScroll() }
        .store(in: &subscriptions)
    }
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    closeButton?.target = view.window
  }

  // MARK: - Section Jumping

  @objc func jumpTo(_ sender: NSButton) {
    jumpToSection(at: sender.tag)
  }

  private func jumpToNextCategorySection() {
    currentSectionIndex = min(currentSectionIndex + 1, collectionView.numberOfSections - 1)
    jumpToSection(at: currentSectionIndex)
    updateCategoryButtons()
  }

  private func jumpToPreviousCategorySection() {
    currentSectionIndex = max(currentSectionIndex - 1, 1)
    jumpToSection(at: currentSectionIndex)
    updateCategoryButtons()
  }

  private func jumpToSection(at index: Int) {
    currentSectionIndex = index
    collectionView.selectionIndexPaths = [IndexPath(item: 0, section: index)]
    collectionView.scrollToItems(at: [IndexPath(item: 0, section: index)], scrollPosition: .top)
    scrollView.contentView.bounds.origin.y -= 26 - 6
    DispatchQueue.main.async { [self] in view.window?.makeFirstResponder(searchField) }
  }

  private func scrollViewDidScroll() {
    let indexPathsForVisibleHeaders = collectionView
      .indexPathsForVisibleSupplementaryElements(ofKind: NSCollectionView.elementKindSectionHeader)
      .filter {
        collectionView.supplementaryView(forElementKind: NSCollectionView.elementKindSectionHeader, at: $0)?
          .frame.intersects(collectionView.visibleRect) == true
      }
      .sorted()

//    let indexPathsForVisibleHeaders = collectionView
//      .indexPathsForVisibleSupplementaryElements(ofKind: NSCollectionView.elementKindSectionHeader)
//      .map { ($0, collectionView.supplementaryView(forElementKind: NSCollectionView.elementKindSectionHeader, at: $0)!) }
//      .filter { $0.1.frame.intersects(collectionView.visibleRect) }
//      //.sorted { $0.1.frame.origin.y > $1.1.frame.origin.y }
//      .map { $0.0 }
//      .sorted()

    guard let section = indexPathsForVisibleHeaders.first?.section, section != currentSectionIndex else { return }
    currentSectionIndex = section
    updateCategoryButtons()
  }

  private func updateCategoryButtons() {
    let categoryButton = categoryButtons[max(currentSectionIndex - 1, 0)]
    categoryButton.state = .on

    let frame = categoryButton.convert(categoryButton.bounds, to: categoryScrollView.contentView)
    categoryScrollView.contentView.scrollToVisible(frame.insetBy(dx: -7/2 - 12, dy: 0))
    //categoryScrollView.scrollToVisible(categoryButton.frame)
  }

  // MARK: Inserting Kaomoji

  @objc func insertKaomoji(_ sender: NSCollectionViewItem) {
    insertKaomoji(sender, withCloseDelay: true)
  }

  private func insertSelected() {
    guard let path = collectionView.selectionIndexPaths.first, let item = collectionView.item(at: path) else { return }
    insertKaomoji(item, withCloseDelay: false)
  }

  private func insertSelectedOrCloseWindow() {
    if !collectionView.selectionIndexPaths.isEmpty {
      insertSelected()
    } else {
      appDelegate.popover?.close()
    }
  }

  private func insertKaomoji(_ sender: NSCollectionViewItem, withCloseDelay: Bool) {
    guard let kaomoji = sender.representedObject as? String else { return }

    if appDelegate.panel.isVisible {
      appDelegate.insertText(kaomoji)
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + (withCloseDelay ? 0.5 : 0)) { [self] in
        appDelegate.popover?.close()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
          appDelegate.insertText(kaomoji)
        }
      }
    }
  }

  // MARK: - Keyboard Navigation

  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    // print(commandSelector)

    func selectFirstIfNeeded() -> Bool {
      if collectionView.selectionIndexPaths.isEmpty {
        collectionView.selectItems(at: [IndexPath(item: 0, section: 1)], scrollPosition: .nearestHorizontalEdge)
        return true
      }

      return false
    }

    switch commandSelector {
    case #selector(moveLeft): if !selectFirstIfNeeded() { collectionView.moveLeft(nil) }
    case #selector(moveRight): if !selectFirstIfNeeded() { collectionView.moveRight(nil) }
    case #selector(moveUp): if !selectFirstIfNeeded() { collectionView.moveUp(nil) }
    case #selector(moveDown): if !selectFirstIfNeeded() { collectionView.moveDown(nil) }
    case #selector(cancelOperation): clearSearchFieldOrCloseWindow()
    case #selector(insertNewline): insertSelectedOrCloseWindow()
    case #selector(insertTab): jumpToNextCategorySection()
    case #selector(insertBacktab): jumpToPreviousCategorySection()
    case #selector(moveToBeginningOfDocument): break // TODO: implement
    case #selector(moveToEndOfDocument): break // TODO: implement
    default: return false
    }

    return true
  }

  // MARK: - Searching

  private static let symbolsByName = [l("heart"): ["♡", "❤"], l("star"): ["☆"]]

  private static func searchTitle(for kaomoji: String) -> String {
    var searchTitle = kaomoji
    for (symbolName, symbols) in symbolsByName {
      for symbol in symbols {
        searchTitle = searchTitle.replacingOccurrences(of: symbol, with: "\(symbolName)")
      }
    }
    return searchTitle
  }

  @objc func search(_ sender: NSSearchField) {
    searchResults = dataSource.kaomoji.flatMap { $0 }.filter {
      $0.localizedCaseInsensitiveContains(sender.stringValue) ||
      Self.searchTitle(for: $0).localizedCaseInsensitiveContains(sender.stringValue)
    }

    placeholderView.isHidden = !isSearching || !searchResults.isEmpty

    collectionView.reloadSections([1])
  }

  func searchFieldDidStartSearching(_ sender: NSSearchField) {
    isSearching = true

    collectionView.performBatchUpdates {
      collectionView.deleteSections(IndexSet(2..<collectionView.numberOfSections))
      collectionView.reloadSections([1])
    }
  }

  func searchFieldDidEndSearching(_ sender: NSSearchField) {
    isSearching = false

    collectionView.performBatchUpdates {
      collectionView.reloadSections([1])
      collectionView.insertSections(IndexSet(2..<categories.count + 1))
    }
  }

  private func clearSearchFieldOrCloseWindow() {
    if let searchField, !searchField.stringValue.isEmpty {
      searchField.stringValue = ""
      search(searchField)
      isSearching = false
      //searchFieldDidEndSearching(searchField)
    } else {
      appDelegate.popover?.close()
    }
  }

  // MARK: - Collection View Data Source

  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    isSearching ? 2 : kaomoji.count + 1
  }

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    section == 0 ? 0 : isSearching ? searchResults.count : kaomoji[section - 1].count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: .item, for: indexPath) as! CollectionViewItem
    item.selectionColor = selectionColor
    item.allowsOnlyOneClick = mode != .settings
    item.representedObject = isSearching ? searchResults[indexPath.item] : kaomoji[indexPath.section - 1][indexPath.item]
    return item
  }

  // TODO: find a way to use the default inter-item gap indicator (i.e. the one that shows up when this method is not implemented)
  func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
    switch kind {
    case NSCollectionView.elementKindSectionHeader:
      if indexPath.section == 0 {
        let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .controlsHeader, for: indexPath) as! CollectionViewControlsHeader
        headerView.searchField.target = self
        headerView.searchField.action = #selector(search(_:))
        headerView.searchField.delegate = self
        headerView.settingsButton.isHidden = mode == .pickerWindow
        searchField = headerView.searchField
        return headerView
      } else {
        let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .sectionHeader, for: indexPath) as! CollectionViewSectionHeader

        headerView.titleTextField.stringValue = usesUppercaseSectionTitles
        ? l(categories[indexPath.section - 1]).localizedUppercase
        : l(categories[indexPath.section - 1])

        if indexPath.section == 1, !showsSearchField, mode == .pickerPopover {
          let settingsButton = NSButton()
          settingsButton.image = .settingsIcon
          settingsButton.target = NSApp.delegate
          settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
          settingsButton.isBordered = false

          headerView.stackView.addArrangedSubview(NSView())
          headerView.stackView.addArrangedSubview(settingsButton)
        }

        return headerView
      }

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
      //return collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .interItemGapIndicator, for: indexPath)
      //return collectionView.supplementaryView(forElementKind: kind, at: indexPath) ?? NSView()

    default:
      return NSView()
    }
  }

  // MARK: - Collection View Delegate

  //  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
  //    print(indexPaths)
  //    guard let indexPath = indexPaths.first else { return }
  //    appDelegate.insertKaomoji(kaomoji[indexPath.section][indexPath.item])
  //  }

  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
    kaomoji[indexPath.section - 1][indexPath.item] as NSString

    // let pasteboardItem = NSPasteboardItem()
    // pasteboardItem.setString(kaomoji[indexPath.section][indexPath.item], forType: .string)
    // return pasteboardItem
  }

  // MARK: - Flow Layout Delegate

  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
    section == 0
    ? NSEdgeInsets(top: 0, left: 8, bottom: isSearching ? 8 : 0, right: 8)
    : (collectionViewLayout as? NSCollectionViewFlowLayout)?.sectionInset ?? .init()
    //: NSEdgeInsets(top: 2, left: 8, bottom: 20, right: 8)
    // TODO: add extra space at end of last section?
  }

  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    section == 0 ? 0 : (collectionViewLayout as? NSCollectionViewFlowLayout)?.minimumLineSpacing ?? 0
  }

  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
    section == 0
    ? NSSize(width: 80, height: showsSearchField ? 33 : 0)
    : NSSize(width: 80, height: isSearching ? 0 : 26)
  }
}

// MARK: -

//extension NSPasteboard.PasteboardType {
//  static let item = Self(UTType.item.identifier)
//}

extension NSUserInterfaceItemIdentifier {
  static let item = Self("item")
  static let sectionHeader = Self("sectionHeader")
  static let controlsHeader = Self("controlsHeader")
  //static let interItemGapIndicator = Self("interItemGapIndicator")
}

extension NSImage {
  static let closeIcon = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
  static let settingsIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
}

// MARK: -

#if DEBUG
import SwiftUI
struct CollectionViewController_Previews: PreviewProvider {
  static var previews: some View {
    NSViewControllerPreview<CollectionViewController>()
      .frame(width: popoverSize.width, height: popoverSize.height)
      .previewDisplayName("Popover")

    NSViewControllerPreview<CollectionViewController>() { $0.mode = .pickerWindow }
      .frame(width: popoverSize.width, height: popoverSize.height + 27)
      .previewDisplayName("Window")

//    NSViewControllerPreview<CollectionViewController>() { $0.showsCategoryButtons = true }
//      .frame(width: popoverSize.width, height: popoverSize.height + 10)
//      .previewDisplayName("Search (Popover)")
//
//    NSViewControllerPreview<CollectionViewController>() { $0.showsCategoryButtons = true; $0.mode = .pickerWindow }
//      .frame(width: popoverSize.width, height: popoverSize.height + 27 + 10)
//      .previewDisplayName("Search (Window)")
  }
}
#endif

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

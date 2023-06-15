import AppKit
import Combine

// TODO: instead of CollectionStyle, maybe use this:
//class BaseCollectionViewController: NSViewController {}
//class PickerCollectionViewController: BaseCollectionViewController {}
//class PopoverCollectionViewController: PickerCollectionViewController {}
//class PanelCollectionViewController: PickerCollectionViewController {}
//class SettingslCollectionViewController: BaseCollectionViewController {}

class CollectionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, NSSearchFieldDelegate, NSControlTextEditingDelegate {
  enum CollectionStyle { case palettePopover, palettePanel, settings }

  private static let recentsCategoryTitle = ".:☆*:･" // "。.:☆*:･"?
  private static let searchBarHeight = 36.0
  private static let sectionHeaderHeight = 26.0

  var collectionStyle = CollectionStyle.palettePopover

  var showsRecents: Bool { !dataSource.recents.isEmpty }
  var showsSearchField = true
  var showsCategoryButtons = true
  var usesMaterialBackground = false
  var usesUppercaseSectionTitles: Bool { true }
  var selectionColor: NSColor { .controlAccentColor.withAlphaComponent(0.25) }

  private(set) var flowLayout: NSCollectionViewFlowLayout!
  private(set) var collectionView: CollectionView!
  private(set) var scrollView: NSScrollView!
  private(set) var stackView: NSStackView!
  private(set) var closeButton: NSButton?
  private(set) var categoryButtons = [CategoryButton]()
  private(set) var categoryScrollView: NSScrollView!
  private(set) var placeholderView: NSTextField!
  private(set) weak var searchField: NSSearchField?

  private var isInserting = false
  private var isSearching = false
  private var searchResults = [String]()
  private var selectionIndexPaths = Set<IndexPath>()
  private var currentSectionIndex = 1

  private var appDelegate: AppDelegate { .shared }
  private var dataSource: DataSource { .shared }
  private var subscriptions = Set<AnyCancellable>()

  private var kaomoji: [[String]] { (showsRecents ? [dataSource.recents] : []) + dataSource.kaomoji }
  private var categories: [String] { (showsRecents ? [l("Recently Used")] : []) + dataSource.categoryNames }

  override func loadView() {
    // TODO: tweak spacing
    flowLayout = NSCollectionViewFlowLayout()
    //flowLayout.itemSize = NSSize(width: 76, height: 24)
    //flowLayout.itemSize = NSSize(width: 83, height: 24)
    flowLayout.itemSize = NSSize(width: 100, height: 24)
    flowLayout.sectionInset = NSEdgeInsets(top: 2, left: 7, bottom: 2, right: 7)

    flowLayout.minimumInteritemSpacing = 3
    flowLayout.minimumLineSpacing = 3
    flowLayout.sectionHeadersPinToVisibleBounds = true

    collectionView = CollectionView()
    collectionView.wantsLayer = true
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
      CollectionViewHeaderSpacer.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: .headerSpacer
    )

//    header.wantsLayer = true
//    header.layer?.borderColor = NSColor.systemIndigo.cgColor
//    header.layer?.borderWidth = 1

    collectionView.registerForDraggedTypes([.string])
    collectionView.setDraggingSourceOperationMask(.copy, forLocal: false)

    //collectionView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    //collectionView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    //collectionView.setContentHuggingPriority(.defaultLow, for: .vertical)
    //collectionView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

    //collectionView.wantsLayer = true
    //collectionView.layer?.borderColor = NSColor.systemBlue.cgColor
    //collectionView.layer?.borderWidth = 1

//    let innerStackView = NSStackView(views: [collectionView])
//    innerStackView.orientation = .vertical
//    //innerStackView.alignment = .trailing
//    //innerStackView.distribution = .fillProportionally
//    innerStackView.spacing = 0
//    //innerStackView.setVisibilityPriority(.,istJp;, for: )
//    //innerStackView.setHuggingPriority(NSLayoutConstraint.Priority., for: .)
//    //innerStackView.detachesHiddenViews = true
//    //innerStackView.setVisibilityPriority(.mustHold, for: collectionView)
//    //innerStackView.setVisibilityPriority(.notVisible, for: header)
//    //innerStackView.setClippingResistancePriority(.defaultHigh, for: .horizontal)
//    //innerStackView.setClippingResistancePriority(.defaultHigh, for: .vertical)
//
//    innerStackView.wantsLayer = true
//    innerStackView.layer?.borderColor = NSColor.systemPink.cgColor
//    innerStackView.layer?.borderWidth = 1
//
//    innerStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//    innerStackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
//    innerStackView.setContentHuggingPriority(.defaultLow, for: .vertical)
//    innerStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

    scrollView = NSScrollView()
    scrollView.autoresizingMask = [.width, .height]
    scrollView.hasVerticalScroller = true
    scrollView.documentView = collectionView
    //scrollView.documentView = innerStackView
    //scrollView.addFloatingSubview(header, for: NSEvent.GestureAxis.vertical)
    scrollView.contentView.postsBoundsChangedNotifications = true
    //scrollView.contentView.wantsLayer = true
    //scrollView.contentView.layer?.borderColor = NSColor.systemGreen.cgColor
    //scrollView.contentView.layer?.borderWidth = 1

    if collectionStyle != .settings {
      let header = CollectionViewHeader2()
      header.translatesAutoresizingMaskIntoConstraints = false
      header.searchField.target = self
      header.searchField.action = #selector(search(_:))
      header.searchField.delegate = self
      header.settingsButton.isHidden = collectionStyle == .palettePanel
      searchField = header.searchField
      collectionView.addSubview(header)

      NSLayoutConstraint.activate([
        //header.widthAnchor.constraint(equalToConstant: popoverSize.width),
        header.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
        header.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
        header.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
      ])
    }

    if showsCategoryButtons {
      for (index, category) in categories.enumerated() {
        let title = showsRecents && index == 0 ? Self.recentsCategoryTitle : kaomoji[orNil: index]?.first ?? "--"
        let button = CategoryButton(radioButtonWithTitle: title, target: self, action: #selector(jumpTo(_:)))
        button.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .bold)
        button.toolTip = l(category)
        button.isBordered = false
        button.imagePosition = .noImage
        button.focusRingType = .exterior
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

      let border = NSBox()
      border.translatesAutoresizingMaskIntoConstraints = false
      border.boxType = .separator

      stackView = NSStackView(views: [scrollView, border, categoryScrollView])

      categoryStackView.wantsLayer = true
      categoryStackView.layer?.sublayerTransform = CATransform3DMakeTranslation(0, 1, 0)
      //categoryStackView.layer?.borderColor = NSColor.systemMint.cgColor
      //categoryStackView.layer?.borderWidth = 1

      NSLayoutConstraint.activate([
        categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor),
        categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.topAnchor),
        categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
        categoryScrollView.heightAnchor.constraint(equalToConstant: 38),
      ])
    } else {
      stackView = NSStackView(views: [scrollView])
    }

    if collectionStyle == .palettePanel {
      // TODO: get better icon?
      let closeButton = NSButton()
      closeButton.image = .closeIcon
      closeButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13.5, weight: .heavy)
      closeButton.action = #selector(NSWindow.close)
      closeButton.isBordered = false
      closeButton.refusesFirstResponder = true
      self.closeButton = closeButton

      let settingsButton = NSButton()
      settingsButton.image = .settingsIcon
      settingsButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13.5, weight: .regular)
      settingsButton.target = NSApp.delegate
      settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
      settingsButton.isBordered = false
      settingsButton.refusesFirstResponder = true

      let titlebarStackView = NSStackView(views: [closeButton, NSView(), settingsButton])
      //titlebarStackView.edgeInsets = NSEdgeInsets(top: 0, left: 7, bottom: 0, right: 11)
      titlebarStackView.edgeInsets = NSEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)

      NSLayoutConstraint.activate([
        closeButton.widthAnchor.constraint(equalToConstant: 14),
        closeButton.heightAnchor.constraint(equalToConstant: 14),
        settingsButton.widthAnchor.constraint(equalToConstant: 14),
        settingsButton.widthAnchor.constraint(equalToConstant: 14),
        titlebarStackView.heightAnchor.constraint(equalToConstant: titlebarHeight),
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
      placeholderView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: Self.searchBarHeight/2),
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

    DataSource.shared.$categories
      .sink { _ in self.collectionView.reloadData() }
      .store(in: &subscriptions)

    DataSource.shared.$kaomoji
      .sink { _ in self.collectionView.reloadData() }
      .store(in: &subscriptions)

    DataSource.shared.$recents
      //.delay(for: 1, scheduler: DispatchQueue.main)
      .sink { [self] _ in if !isSearching, !isInserting { collectionView.reloadData() } }
      .store(in: &subscriptions)

//    DataSource.shared.kaomojiOrCategoriesDidChange
//      .sink { _ in self.collectionView.reloadData() }
//      .store(in: &subscriptions)

    if collectionStyle != .settings {
      NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        .sink { _ in self.scrollViewDidScroll() }
        .store(in: &subscriptions)
    }
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    closeButton?.target = view.window
    collectionView.reloadData()
  }

  // MARK: - Section Jumping

  @objc func jumpTo(_ sender: NSButton) {
    clearSearchFieldAndStopSearching()
    jumpToSection(at: sender.tag)
    updateCategoryButtons()
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
    scrollView.contentView.bounds.origin.y -= Self.sectionHeaderHeight - 6
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
    guard let categoryButton = categoryButtons[orNil: max(currentSectionIndex - 1, 0)] else { return }
    categoryButton.state = isSearching ? .off : .on

    let frame = categoryButton.convert(categoryButton.bounds, to: categoryScrollView.contentView)
    categoryScrollView.contentView.scrollToVisible(frame.insetBy(dx: -7/2 - 12, dy: 0))
  }

  // MARK: - Inserting Kaomoji

  private func insertSelected() {
    guard let path = collectionView.selectionIndexPaths.first, let item = collectionView.item(at: path) else { return }

    insertKaomoji(item, withCloseDelay: false)
  }

  private func insertSelectedOrSelectFirstOrCloseWindow() -> Bool {
    if !collectionView.selectionIndexPaths.isEmpty {
      insertSelected()
    } else if isSearching {
      guard !searchResults.isEmpty else { return false }
      collectionView.selectionIndexPaths = [IndexPath(item: 0, section: 1)]
    } else {
      appDelegate.popover?.close()
    }

    return true
  }

  private func insertKaomoji(_ sender: NSCollectionViewItem, withCloseDelay: Bool) {
    guard let kaomoji = sender.representedObject as? String else { return }

    isInserting = true
    dataSource.addKaomojiToRecents(kaomoji)

    if appDelegate.panel.isVisible {
      if NSApp.currentEvent?.type == .keyDown {
        NSApp.deactivate()
      }

      appDelegate.insertText(kaomoji)

      isInserting = false
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + (withCloseDelay ? 0.5 : 0)) { [self] in
        appDelegate.popover?.close()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
          NSApp.deactivate()

          appDelegate.insertText(kaomoji)

          isInserting = false
        }
      }
    }
  }

  // MARK: - Keyboard Navigation

  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    // print(commandSelector)

    func selectFirstIfNeeded() -> Bool {
      if collectionView.selectionIndexPaths.isEmpty {
        collectionView.selectionIndexPaths = [IndexPath(item: 0, section: currentSectionIndex)]
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
    case #selector(insertNewline): return insertSelectedOrSelectFirstOrCloseWindow()
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
        searchTitle = searchTitle.replacingOccurrences(of: symbol, with: symbolName)
      }
    }
    return searchTitle
  }

  @objc func search(_ sender: NSSearchField) {
    guard !dataSource.kaomoji.isEmpty else { return }

    searchResults = dataSource.kaomoji.flatMap { $0 }.filter {
      $0.localizedCaseInsensitiveContains(sender.stringValue) ||
      Self.searchTitle(for: $0).localizedCaseInsensitiveContains(sender.stringValue)
    }

    placeholderView.isHidden = !isSearching || !searchResults.isEmpty

    collectionView.reloadSections([1])
  }

  func searchFieldDidStartSearching(_ sender: NSSearchField) {
    guard !isSearching, !dataSource.kaomoji.isEmpty else { return }
    isSearching = true

    collectionView.performBatchUpdates {
      collectionView.deleteSections(IndexSet(2..<collectionView.numberOfSections))
      collectionView.reloadSections([1])
    } completionHandler: { [self] finished in
      if finished {
        flowLayout.sectionHeadersPinToVisibleBounds = false
        updateCategoryButtons()
      }
    }
  }

  func searchFieldDidEndSearching(_ sender: NSSearchField) {
    guard isSearching, !dataSource.kaomoji.isEmpty else { return }
    isSearching = false

    collectionView.performBatchUpdates {
      collectionView.reloadSections([1])
      collectionView.insertSections(IndexSet(2..<categories.count + 1))
    } completionHandler: { [self] finished in
      if finished {
        flowLayout.sectionHeadersPinToVisibleBounds = true
        updateCategoryButtons()
      }
    }
  }

  private func clearSearchFieldAndStopSearching() {
    guard let searchField, let cell = searchField.cell as? NSSearchFieldCell, !cell.stringValue.isEmpty else { return }

    cell.cancelButtonCell?.performClick(nil)
    searchFieldDidEndSearching(searchField)
  }

  private func clearSearchFieldOrCloseWindow() {
    if searchField?.stringValue.isEmpty == false {
      clearSearchFieldAndStopSearching()
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
    item.representedObject = isSearching ? searchResults[indexPath.item] : kaomoji[indexPath.section - 1][orNil: indexPath.item]
    return item
  }

  // TODO: find a way to use the default inter-item gap indicator (i.e. the one that shows up when this method is not implemented)
  func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
    switch kind {
    case NSCollectionView.elementKindSectionHeader:
      if indexPath.section == 0 {
        let header = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .headerSpacer, for: indexPath) as! CollectionViewHeaderSpacer
        //header.searchField.target = self
        //header.searchField.action = #selector(search(_:))
        //header.searchField.delegate = self
        //header.settingsButton.isHidden = collectionStyle == .palettePanel
        // //searchField = header.searchField
        //header.alphaValue = 0
        //header.isHidden = true
        return header
      } else {
        let header = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .sectionHeader, for: indexPath) as! CollectionViewSectionHeader

        header.titleTextField.stringValue = usesUppercaseSectionTitles
        ? l(categories[indexPath.section - 1]).localizedUppercase
        : l(categories[indexPath.section - 1])

//        headerView.titleTextField.stringValue = l(categories[indexPath.section - 1])
//        if usesUppercaseSectionTitles {
//          headerView.titleTextField.stringValue = headerView.titleTextField.stringValue.localizedUppercase
//        }
//
//        let title: String
//        if usesUppercaseSectionTitles {
//          title = l(categories[indexPath.section - 1]).localizedUppercase
//        } else {
//          title = l(categories[indexPath.section - 1])
//        }
//        headerView.titleTextField.stringValue = title

//        if indexPath.section == 1, !showsSearchField, collectionStyle == .palettePopover {
//          let settingsButton = NSButton()
//          settingsButton.image = .settingsIcon
//          settingsButton.target = NSApp.delegate
//          settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
//          settingsButton.isBordered = false
//          settingsButton.refusesFirstResponder = true
//
//          headerView.stackView.addArrangedSubview(NSView())
//          headerView.stackView.addArrangedSubview(settingsButton)
//        }

        return header
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

  // MARK: - Item Click Handling

  @objc func collectionViewItemWasClicked(_ sender: CollectionViewItem) {
    guard !isInserting else { return }

    insertKaomoji(sender, withCloseDelay: true)
  }

  @objc func collectionViewItemWasDoubleClicked(_ sender: CollectionViewItem) {
    collectionViewItemWasClicked(sender)
  }

  // MARK: - Collection View Delegate

  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
    guard !isInserting else { return nil }
    return (collectionView.item(at: indexPath) as? CollectionViewItem)?.representedObject as? NSString
    //kaomoji[indexPath.section - 1][indexPath.item] as NSString

    // let pasteboardItem = NSPasteboardItem()
    // pasteboardItem.setString(kaomoji[indexPath.section][indexPath.item], forType: .string)
    // return pasteboardItem
  }

//  func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
//    return draggingInfo.draggingSourceOperationMask
//  }

  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
    //session.draggingFormation = .list
    //session.animatesToStartingPositionsOnCancelOrFail = false
  }

  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
    if operation == .copy, let kaomoji = session.draggingPasteboard.string(forType: .string) {
      dataSource.addKaomojiToRecents(kaomoji)
      appDelegate.popover?.close()
    }
  }

  func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
    isInserting ? selectionIndexPaths : indexPaths
  }

  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    selectionIndexPaths = indexPaths
  }

  // MARK: - Flow Layout Delegate

  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
    var sectionInset = (collectionViewLayout as? NSCollectionViewFlowLayout)?.sectionInset ?? .init()
    if section == 0 { sectionInset = NSEdgeInsets(top: 0, left: 8, bottom: isSearching ? 8 : 0, right: 8) }
    if section == collectionView.numberOfSections - 1 { sectionInset.bottom += 5 }
    return sectionInset
  }

  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    section == 0 ? 0 : (collectionViewLayout as? NSCollectionViewFlowLayout)?.minimumLineSpacing ?? 0
  }

  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
    section == 0
    ? NSSize(width: popoverSize.width, height: showsSearchField ? Self.searchBarHeight : 0)
    : NSSize(width: popoverSize.width, height: isSearching ? 0 : Self.sectionHeaderHeight)
  }
}

// MARK: -

class CollectionView: NSCollectionView {
  /// Whether moving popover by dragging background is enabled.
  var mouseDownCanMovePopover = true

  /// If enabled, move popover by dragging background.
  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)

    if mouseDownCanMovePopover, indexPathForItem(at: convert(event.locationInWindow, from: nil)) == nil {
      AppDelegate.shared.popover?.mouseDown(with: event)
    }
  }

  /// Scroll selected items into view while taking heights of section headers into account.
  private func scrollSelectionToVisible() {
    guard
      let clipView = enclosingScrollView?.contentView,
      let indexPath = selectionIndexPaths.sorted().first,
      let sectionHeader = supplementaryView(
        forElementKind: NSCollectionView.elementKindSectionHeader,
        at: IndexPath(item: 0, section: indexPath.section)
      ),
      let item = item(at: indexPath)
    else { return }

    //print(clipView, indexPath, sectionHeader, item)
    //print(item.view.frame, sectionHeader.frame, item.view.frame.intersects(sectionHeader.frame))

    if sectionHeader.frame.intersects(item.view.frame) {
      let overlapHeight = max(0, min(sectionHeader.frame.maxY, item.view.frame.maxY)
                              - max(sectionHeader.frame.minY, item.view.frame.minY))

      //print(sectionHeader.frame, sectionHeader.convert(sectionHeader.bounds, to: clipView), overlapHeight)
      //clipView.scrollToVisible(sectionHeader.convert(sectionHeader.bounds, to: clipView))
      clipView.bounds.origin.y -= overlapHeight
    }

//    var frame = item.view.convert(item.view.bounds, to: clipView)
//    frame.origin.y += sectionHeader.convert(sectionHeader.bounds, to: clipView).origin.y
//    clipView.scrollToVisible(frame)
  }

  override func moveLeft(_ sender: Any?) { super.moveLeft(sender); scrollSelectionToVisible() }
  override func moveRight(_ sender: Any?) { super.moveRight(sender); scrollSelectionToVisible() }
  override func moveUp(_ sender: Any?) { super.moveUp(sender); scrollSelectionToVisible() }
  override func moveDown(_ sender: Any?) { super.moveDown(sender); scrollSelectionToVisible() }

  // TODO: implement this but for moveLeft/Right/Up/Down instead?
  // override func becomeFirstResponder() -> Bool {
  //   if selectionIndexPaths.isEmpty {
  //     for section in 0..<numberOfSections {
  //       if numberOfItems(inSection: section) > 0 {
  //         selectionIndexPaths = [IndexPath(item: 0, section: section)]
  //         break
  //       }
  //     }
  //   }
  //
  //   return super.becomeFirstResponder()
  // }
}

//extension NSPasteboard.PasteboardType {
//  static let item = Self(UTType.item.identifier)
//}

extension NSUserInterfaceItemIdentifier {
  static let item = Self("item")
  static let sectionHeader = Self("sectionHeader")
  static let headerSpacer = Self("headerSpacer")
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

    NSViewControllerPreview<CollectionViewController>() { $0.collectionStyle = .palettePanel }
      .frame(width: popoverSize.width, height: popoverSize.height + titlebarHeight)
      .previewDisplayName("Panel")

//    NSViewControllerPreview<CollectionViewController>() { $0.showsCategoryButtons = true }
//      .frame(width: popoverSize.width, height: popoverSize.height + 10)
//      .previewDisplayName("Search (Popover)")
//
//    NSViewControllerPreview<CollectionViewController>() { $0.showsCategoryButtons = true; $0.collectionStyle = .palettePanel }
//      .frame(width: popoverSize.width, height: popoverSize.height + titlebarHeight + 10)
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

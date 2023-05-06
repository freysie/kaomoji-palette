import AppKit

// TODO: settings?
// TODO: drag kaomoji out of the picker
// TODO: more AXUIElement edge cases
// TODO: frequently used

class KaomojiPickerViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
  var collectionView: NSCollectionView!

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

    collectionView.register(
      KaomojiPickerCollectionViewHeader.self,
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: NSUserInterfaceItemIdentifier("header")
    )

    collectionView.registerForDraggedTypes([.string])

    //let scrollView = KaomojiPickerScrollView()
    let scrollView = NSScrollView()
    scrollView.autoresizingMask = [.width, .height]
    scrollView.hasVerticalScroller = true
    scrollView.documentView = collectionView
    scrollView.drawsBackground = false

//    let effectView = NSVisualEffectView()
//    effectView.material = .hudWindow
//    effectView.blendingMode = .behindWindow
//    effectView.addSubview(scrollView)

//    view = effectView
    view = scrollView
  }

  override func cancelOperation(_ sender: Any?) {
    view.window?.close()
  }

  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    kaomoji.count
  }

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    kaomoji[section].count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = KaomojiPickerCollectionViewItem()
    item.loadView()
    item.textField?.stringValue = kaomoji[indexPath.section][indexPath.item]
    return item
  }

  func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
    let headerView = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier("header"), for: indexPath) as! KaomojiPickerCollectionViewHeader

    headerView.titleTextField.stringValue = kaomojiSectionTitles[indexPath.section].localizedUppercase

    return headerView
  }

  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
    //kaomoji[indexPath.section][indexPath.item] as NSString
    let pasteboardItem = NSPasteboardItem()
    pasteboardItem.setString(kaomoji[indexPath.section][indexPath.item], forType: .string)
    return pasteboardItem
  }

//  @objc func didDoubleClickItem(_ sender: NSGestureRecognizer) {
//    guard let item
//  }
}

///// Used to make the visual effect view cover the arrow portion of the popover.
//class KaomojiPickerScrollView: NSScrollView {
//  override func viewDidMoveToWindow() {
//    guard let frameView = window?.contentView?.superview else { return }
//
//    let effectView = NSVisualEffectView(frame: frameView.bounds)
//    effectView.material = .hudWindow
//    effectView.blendingMode = .behindWindow
//
//    frameView.addSubview(effectView, positioned: .below, relativeTo: frameView)
//  }
//}

#if DEBUG
import SwiftUI
struct KaomojiPickerViewController_Previews: PreviewProvider {
  static var previews: some View {
    NSViewControllerPreview {
      KaomojiPickerViewController()
    }
    .frame(width: 320, height: 358)
  }
}
#endif

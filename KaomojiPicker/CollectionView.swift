import AppKit

class CollectionView: NSCollectionView {
  // override var mouseDownCanMoveWindow: Bool { true }

  /// Move popover by background.
  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)

    if indexPathForItem(at: convert(event.locationInWindow, from: nil)) == nil {
      AppDelegate.shared.popover?.mouseDown(with: event)
    }
  }

  // TODO: implement this but for moveLeft/Right/Up/Down instead
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

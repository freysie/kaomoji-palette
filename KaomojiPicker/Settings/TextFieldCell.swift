import SwiftUI

/// … _sigh_.
class TextFieldCell: NSTextFieldCell {
  var isEditingOrSelecting = false

  override func drawingRect(forBounds theRect: NSRect) -> NSRect {
    var newRect = super.drawingRect(forBounds: theRect)

    if !isEditingOrSelecting {
      let textSize = self.cellSize(forBounds: theRect)

      let heightDelta: CGFloat = newRect.size.height - textSize.height
      if heightDelta > 0 {
        newRect.size.height -= heightDelta.rounded()
        newRect.origin.y += (heightDelta / 2).rounded()
      }
    }

    return newRect
  }

  override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
    let rect = self.drawingRect(forBounds: rect)
    isEditingOrSelecting = true
    super.select(withFrame: rect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    isEditingOrSelecting = false
  }

  override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
    let rect = self.drawingRect(forBounds: rect)
    isEditingOrSelecting = true
    super.edit(withFrame: rect, in: controlView, editor: textObj, delegate: delegate, event: event)
    isEditingOrSelecting = false
  }
}

import AppKit

class CategoryButton: NSButton {
  override class var cellClass: AnyClass? { get { CategoryButtonCell.self } set {} }
}

class CategoryButtonCell: NSButtonCell {
  override var attributedTitle: NSAttributedString {
    get {
      NSAttributedString(string: title, attributes: [
        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .semibold),
        .foregroundColor: isHighlighted
        ? NSColor.controlTextColor : state == .on
        ? NSColor.controlAccentColor.withSystemEffect(.pressed)
        : NSColor.controlTextColor.withAlphaComponent(0.9)
      ])
    }
    set {}
  }
}

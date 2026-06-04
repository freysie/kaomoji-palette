import AppKit

class SearchField: NSSearchField {
  override class var cellClass: AnyClass? {
    get { if #available(macOS 26, *) { SearchFieldCell.self } else { NSSearchFieldCell.self } }
    set {}
  }
}

@available(macOS 26, *)
class SearchFieldCell: NSSearchFieldCell {
  override func searchTextRect(forBounds rect: NSRect) -> NSRect {
    var rect = super.searchTextRect(forBounds: rect)
    rect.origin.x -= 10
    rect.size.width += 10
    return rect
  }

  override func searchButtonRect(forBounds rect: NSRect) -> NSRect {
    var rect = super.searchButtonRect(forBounds: rect)
    rect.origin.x -= 5
    rect.origin.y -= 1
    return rect
  }

  // TODO: figure out a way to show the sidebar-style search field outside of sidebars
  // this is a fair approximation of its appearance, but we’re missing at least some background blur
  override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
    NSColor.secondarySystemFill.setFill()
    NSBezierPath(roundedRect: cellFrame, xRadius: 14, yRadius: 14).fill()

    drawInterior(withFrame: cellFrame, in: controlView)
  }
}

extension NSSize {
  func scaledRect(toFit rect: NSRect) -> NSRect {
    let scale = min(rect.width / width, rect.height / height)
    let newSize = NSSize(width: width * scale, height: height * scale)

    return NSRect(
      x: rect.midX - newSize.width / 2,
      y: rect.midY - newSize.height / 2,
      width: newSize.width,
      height: newSize.height
    )
  }
}

class CollectionViewHeader: NSView {
  private(set) var searchField: NSSearchField!
  private(set) var settingsButton: NSButton!

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    searchField = SearchField()
    if #available(macOS 26, *) {
      searchField.controlSize = .large
    }

    settingsButton = NSButton()
    settingsButton.image = .settingsIcon
    settingsButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13.5, weight: .regular)
    settingsButton.target = NSApp.delegate
    settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
    settingsButton.isBordered = false
    settingsButton.refusesFirstResponder = true

    let stackView = NSStackView(views: [searchField, settingsButton])
    stackView.edgeInsets = if #available(macOS 26, *) {
      NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    } else {
      NSEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
    }
    stackView.spacing = 6
    addSubview(stackView)

    if #available(macOS 26, *) {
      NSLayoutConstraint.activate([
        searchField.heightAnchor.constraint(equalToConstant: 28),
      ])
    }

    NSLayoutConstraint.activate([
      settingsButton.widthAnchor.constraint(equalToConstant: 29),
      settingsButton.heightAnchor.constraint(equalToConstant: 15),

      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 11),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var mouseDownCanMoveWindow: Bool { true }
}

class CollectionViewHeaderSpacer: NSView, NSCollectionViewElement {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    if #available(macOS 26, *) {
      // TODO
    } else {
      NSLayoutConstraint.activate([
        heightAnchor.constraint(equalToConstant: CollectionViewController.searchBarHeight),
      ])
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

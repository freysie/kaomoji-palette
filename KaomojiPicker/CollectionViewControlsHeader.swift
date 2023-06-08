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

class CollectionViewControlsHeader: NSView, NSCollectionViewElement {
  private(set) var searchField: NSSearchField!
  private(set) var settingsButton: NSButton!

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    searchField = NSSearchField()

    settingsButton = NSButton()
    settingsButton.image = .settingsIcon
    settingsButton.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13.5, weight: .regular)
    settingsButton.target = NSApp.delegate
    settingsButton.action = #selector(AppDelegate.showSettingsWindow(_:))
    settingsButton.isBordered = false
    settingsButton.focusRingType = .none

    let stackView = NSStackView(views: [searchField, settingsButton])
    stackView.edgeInsets = NSEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
    stackView.spacing = 6
    addSubview(stackView)

    NSLayoutConstraint.activate([
      settingsButton.widthAnchor.constraint(equalToConstant: 29),
      settingsButton.heightAnchor.constraint(equalToConstant: 15),

      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 11),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    //stackView.wantsLayer = true
    //stackView.layer?.borderWidth = 1
    //stackView.layer?.borderColor = NSColor.systemMint.cgColor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  //override func prepareForReuse() {
  //  super.prepareForReuse()
  //  print(#function)
  //}
}

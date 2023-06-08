import AppKit

class CollectionViewItem: NSCollectionViewItem {
  private(set) var titleTextField: NSTextField!
  var selectionColor = NSColor.controlAccentColor
  var allowsOnlyOneClick = false

  override func loadView() {
    titleTextField = CollectionViewItemTextField(labelWithString: "")
    titleTextField.translatesAutoresizingMaskIntoConstraints = false
    titleTextField.alignment = .center
    titleTextField.lineBreakMode = .byTruncatingTail
    titleTextField.allowsExpansionToolTips = true
    textField = titleTextField

    view = NSView()
    view.wantsLayer = true
    view.layer?.cornerRadius = 5
    view.addSubview(titleTextField)

    NSLayoutConstraint.activate([
      titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1),
      titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1),
      titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 3),
      titleTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
    ])
  }

  override var representedObject: Any? {
    didSet {
      titleTextField.objectValue = representedObject
    }
  }

  override var isSelected: Bool {
    didSet {
      view.layer?.backgroundColor = isSelected ? selectionColor.cgColor : nil

      if selectionColor == .controlAccentColor {
        titleTextField.textColor = isSelected ? .alternateSelectedControlTextColor : nil
      }
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    view.layer?.backgroundColor = nil
  }

// FIXME: don’t insert if dragged

//  var wasDragging = false
//
//  override func mouseDown(with event: NSEvent) {
//    super.mouseDown(with: event)
//
//    wasDragging = false
//  }
//
//  override func mouseDragged(with event: NSEvent) {
//    super.mouseDragged(with: event)
//
//    wasDragging = true
//  }

  override func mouseUp(with theEvent: NSEvent) {
    guard !allowsOnlyOneClick || collectionView?.selectionIndexPaths.isEmpty == true else { return }

    //guard !wasDragging, let appDelegate = NSApp.delegate as? AppDelegate else { return }
    // TODO: add double-clicking support for settings

    NSApp.sendAction(#selector(CollectionViewController.insertKaomoji(_:)), to: collectionView?.delegate, from: self)

    super.mouseUp(with: theEvent)
  }

  override func insertNewline(_ sender: Any?) {
    NSApp.sendAction(#selector(CollectionViewController.insertKaomoji(_:)), to: collectionView?.delegate, from: self)
  }
}

class CollectionViewItemTextField: NSTextField {
  override var mouseDownCanMoveWindow: Bool { false }
}

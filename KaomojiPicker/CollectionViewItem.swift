import AppKit

class CollectionViewItem: NSCollectionViewItem {
  var titleTextField: NSTextField!
//  var settingsMode = false
  var selectionColor = NSColor.controlAccentColor

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
      titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
      titleTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
    ])
  }

  override var isSelected: Bool {
    didSet {
      view.layer?.backgroundColor = isSelected ? selectionColor.cgColor : nil
    }
  }

  override func prepareForReuse() {
    view.layer?.backgroundColor = nil
  }

  // TODO: move to collection view controller
  // TODO: add double-clicking support for settings
  func insert() {
    return
    guard let appDelegate = NSApp.delegate as? AppDelegate else { return }

    if appDelegate.popover?.isDetached == false {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
        appDelegate.popover?.close()
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
          appDelegate.insertText(titleTextField.stringValue)
        //}
      }
    } else {
      appDelegate.insertText(titleTextField.stringValue)
    }
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
    super.mouseUp(with: theEvent)

    //guard !wasDragging, let appDelegate = NSApp.delegate as? AppDelegate else { return }
    insert()
  }

  override func insertNewline(_ sender: Any?) {
    insert()
  }
}

class CollectionViewItemTextField: NSTextField {
  override var mouseDownCanMoveWindow: Bool { false }
}

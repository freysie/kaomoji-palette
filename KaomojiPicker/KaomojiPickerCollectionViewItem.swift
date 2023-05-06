import AppKit

class KaomojiPickerCollectionViewItem: NSCollectionViewItem {
  var titleTextField: NSTextField!

  override func loadView() {
    titleTextField = KaomoijPickerCollectionViewItemTextField(labelWithString: "")
    titleTextField.translatesAutoresizingMaskIntoConstraints = false
    titleTextField.alignment = .center
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
      view.layer?.backgroundColor = isSelected ? NSColor.selectedContentBackgroundColor.cgColor : NSColor.clear.cgColor
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
    guard let appDelegate = NSApp.delegate as? AppDelegate else { return }

    if appDelegate.popover?.isDetached != true {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
        appDelegate.popover?.close()
        appDelegate.insertText(titleTextField.stringValue)
      }
    } else {
      appDelegate.insertText(titleTextField.stringValue)
    }
  }
}

class KaomoijPickerCollectionViewItemTextField: NSTextField {
  override var mouseDownCanMoveWindow: Bool { false }
}

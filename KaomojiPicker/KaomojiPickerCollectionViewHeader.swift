import AppKit

class KaomojiPickerCollectionViewHeader: NSVisualEffectView, NSCollectionViewElement {
  var titleTextField: NSTextField!

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    material = .popover
    blendingMode = .behindWindow

    titleTextField = NSTextField(labelWithString: "")
    titleTextField.translatesAutoresizingMaskIntoConstraints = false
    titleTextField.textColor = .secondaryLabelColor
    addSubview(titleTextField)

    NSLayoutConstraint.activate([
      titleTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      titleTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      titleTextField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      titleTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

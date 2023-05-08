import AppKit

class KaomojiCollectionViewSectionHeader: NSVisualEffectView, NSCollectionViewElement {
  var stackView: NSStackView!
  var titleTextField: NSTextField!

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    material = .popover
    blendingMode = .behindWindow

    titleTextField = NSTextField(labelWithString: "")
    titleTextField.translatesAutoresizingMaskIntoConstraints = false
    titleTextField.textColor = .secondaryLabelColor

    stackView = NSStackView(views: [titleTextField])
    stackView.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 0, right: 16)
    stackView.wantsLayer = true
    //stackView.layer?.borderColor = .white
    //stackView.layer?.borderWidth = 1
    // TODO: find out why the top edge inset is not working, then remove this:
    stackView.layer?.sublayerTransform = CATransform3DMakeTranslation(0, -4, 0)
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.heightAnchor.constraint(equalToConstant: 27),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    stackView.arrangedSubviews.forEach(stackView.removeView)
    stackView.addArrangedSubview(titleTextField)
  }
}

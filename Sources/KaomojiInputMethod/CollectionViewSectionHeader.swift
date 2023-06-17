import AppKit

class CollectionViewSectionHeader: NSVisualEffectView, NSCollectionViewElement {
  private(set) var stackView: NSStackView!
  private(set) var titleTextField: NSTextField!
  private(set) var stackViewTopAnchor: NSLayoutConstraint!
  private(set) var stackViewBottomAnchor: NSLayoutConstraint!

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    wantsLayer = true
    material = .popover
    blendingMode = .behindWindow

    titleTextField = NSTextField(labelWithString: "")
    titleTextField.wantsLayer = true
    titleTextField.translatesAutoresizingMaskIntoConstraints = false
    titleTextField.font = .systemFont(ofSize: NSFont.smallSystemFontSize + 1)
    titleTextField.textColor = .secondaryLabelColor

    stackView = NSStackView(views: [titleTextField])
    stackView.edgeInsets = NSEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    stackView.wantsLayer = true
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.5)
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    stackView.arrangedSubviews.forEach(stackView.removeView)
    stackView.addArrangedSubview(titleTextField)
  }
}

#if DEBUG
import SwiftUI
struct CollectionViewSectionHeader_Previews: PreviewProvider {
  static var previews: some View {
    NSViewPreview {
      let header = CollectionViewSectionHeader()
      header.titleTextField.stringValue = l("Joy")
      NSLayoutConstraint.activate([
        header.widthAnchor.constraint(equalToConstant: popoverSize.width),
        header.heightAnchor.constraint(equalToConstant: CollectionViewController.sectionHeaderHeight),
      ])
      return header
    }
    .previewLayout(.sizeThatFits)
  }
}
#endif

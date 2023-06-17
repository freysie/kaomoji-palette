import SwiftUI

struct NSViewPreview<View: NSView>: NSViewRepresentable {
  let view: View
  init(_ builder: @escaping () -> View) { view = builder() }
  init(_ setUp: ((View) -> ())? = nil) { view = View(); setUp?(view) }
  func makeNSView(context: Context) -> NSView { view }
  func updateNSView(_ view: NSView, context: Context) {
    view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    view.setContentHuggingPriority(.defaultHigh, for: .vertical)
  }
}

struct NSViewControllerPreview<ViewController: NSViewController>: NSViewControllerRepresentable {
  let viewController: ViewController
  init(_ builder: @escaping () -> ViewController) { viewController = builder() }
  init(_ setUp: ((ViewController) -> ())? = nil) { viewController = ViewController(); setUp?(viewController) }
  func makeNSViewController(context: Context) -> NSViewController { viewController }
  func updateNSViewController(_ viewController: NSViewController, context: Context) {
    viewController.view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    viewController.view.setContentHuggingPriority(.defaultHigh, for: .vertical)
  }
}

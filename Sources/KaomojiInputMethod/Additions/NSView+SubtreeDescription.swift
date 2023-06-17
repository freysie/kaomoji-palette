import AppKit

extension NSView {
  var subtreeDescription: String {
    perform(Selector(("_subtreeDescription"))).takeUnretainedValue() as! String
  }
}

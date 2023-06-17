import AppKit

extension NSImage {
  static func cornerMask(radius: CGFloat) -> NSImage {
    let image = NSImage(size: NSMakeSize(radius * 2, radius * 2), flipped: false) { rect in
      NSColor.black.setFill()
      NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
      return true
    }

    image.capInsets = NSEdgeInsetsMake(radius, radius, radius, radius)

    return image
  }
}

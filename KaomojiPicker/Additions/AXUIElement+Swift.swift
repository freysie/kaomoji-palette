import AppKit
import ApplicationServices

extension AXUIElement {
  static let systemWide = AXUIElementCreateSystemWide()

  private func get<T>(_ attribute: String, as _: T.Type = T.self) -> T? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self, attribute as CFString, &value)
    if result != .success { NSLog("error getting \(self)[\(attribute)]: \(result.rawValue)") }
    return value as? T
  }

  private func get<T>(_ attribute: String, _ parameter: CFTypeRef, as: T.Type) -> T? {
    var value: CFTypeRef?
    let result = AXUIElementCopyParameterizedAttributeValue(self, attribute as CFString, parameter, &value)
    if result != .success { NSLog("error getting \(self)[\(attribute)(\(parameter))]: \(result.rawValue)") }
    return value as? T
  }

  private func set(_ attribute: String, _ value: Any?) {
    let result = AXUIElementSetAttributeValue(self, attribute as CFString, value as? CFTypeRef ?? kCFNull)
    if result != .success { NSLog("error setting \(self)[\(attribute)]: \(result.rawValue)") }
  }

  var attributeNames: [String]? {
    var attributeNames: CFArray?
    let result = AXUIElementCopyAttributeNames(self, &attributeNames)
    if result != .success { NSLog("error getting attribute names: \(result.rawValue)") }
    return attributeNames as? [String]
  }

  var parameterizedAttributeNames: [String]? {
    var parameterizedAttributeNames: CFArray?
    let result = AXUIElementCopyParameterizedAttributeNames(self, &parameterizedAttributeNames)
    if result != .success { NSLog("error getting parameterized attribute names: \(result.rawValue)") }
    return parameterizedAttributeNames as? [String]
  }

  var processID: pid_t? {
    var pid: pid_t = 0
    return AXUIElementGetPid(self, &pid) == .success ? pid : nil
  }

  var focusedUIElement: AXUIElement? {
    `get`(kAXFocusedUIElementAttribute)
  }

  var selectedTextRange: CFRange? {
    get { get(kAXSelectedTextRangeAttribute, as: AXValue.self)?.asRange }
    set { set(kAXSelectedTextRangeAttribute, newValue.map(AXValue.range(_:))) }
  }

  var selectedTextMarkerRange: AXTextMarkerRange? {
    get { get("AXSelectedTextMarkerRange") }
    set { set("AXSelectedTextMarkerRange", newValue) }
  }

  var visibleCharacterRange: CFRange? {
    `get`(kAXVisibleCharacterRangeAttribute, as: AXValue.self)?.asRange
  }

  var frame: CGRect? {
    `get`("AXFrame", as: AXValue.self)?.asRect
  }

  var position: CGPoint? {
    `get`(kAXPositionAttribute, as: AXValue.self)?.asPoint
  }

  var size: CGSize? {
    `get`(kAXSizeAttribute, as: AXValue.self)?.asSize
  }

  var value: String? {
    get { get(kAXValueAttribute, as: CFString.self) as String? }
    set { set(kAXValueAttribute, newValue) }
  }

  var children: [AXUIElement]? {
    `get`(kAXChildrenAttribute, as: CFArray.self) as? [AXUIElement]
  }

  var sharedTextUIElements: [AXUIElement]? {
    `get`(kAXSharedTextUIElementsAttribute, as: CFArray.self) as? [AXUIElement]
  }

  var searchButton: AXUIElement? {
    `get`("AXSearchButton")
  }

  var primaryScreenHeight: CGFloat? {
    `get`("_AXPrimaryScreenHeight")
  }

  var insertionPointLineNumber: Int? {
    `get`(kAXInsertionPointLineNumberAttribute)
  }

  func bounds(for range: CFRange) -> CGRect? {
    get(kAXBoundsForRangeParameterizedAttribute, AXValue.range(range), as: AXValue.self)?.asRect
      .flatMap(NSScreen.convertFromQuartz)
  }

  func bounds(for range: AXTextMarkerRange) -> CGRect? {
    get("AXBoundsForTextMarkerRange", range, as: AXValue.self)?.asRect
      .flatMap(NSScreen.convertFromQuartz)
  }

  func attributedString(for range: CFRange) -> NSAttributedString? {
    get(kAXAttributedStringForRangeParameterizedAttribute, AXValue.range(range), as: CFAttributedString.self)
  }

  var cursorBounds: CGRect? {
    if let selection = selectedTextRange, selection.length == 0 {
      let queryRange =
        selection.location > 0
          ? CFRange(location: selection.location - 1, length: 1)
          : selection
      return bounds(for: queryRange)
    }
    return nil
  }
}

extension AXValue {
  private func get<T>(_ type: AXValueType, initial: T) -> T? {
    var result = initial
    return AXValueGetValue(self, type, &result) ? result : nil
  }
  var asPoint: CGPoint? { return get(.cgPoint, initial: .zero) }
  var asSize: CGSize? { return get(.cgSize, initial: .zero) }
  var asRect: CGRect? { return get(.cgRect, initial: .zero) }
  var asRange: CFRange? { return get(.cfRange, initial: CFRange()) }
  var asError: AXError? { return get(.axError, initial: .success) }

  private static func create<T>(_ type: AXValueType, _ value: T) -> AXValue {
    var value = value
    return AXValueCreate(type, &value)!
  }
  static func point(_ v: CGPoint) -> AXValue { return create(.cgPoint, v) }
  static func size(_ v: CGSize) -> AXValue { return create(.cgSize, v) }
  static func rect(_ v: CGRect) -> AXValue { return create(.cgRect, v) }
  static func range(_ v: CFRange) -> AXValue { return create(.cfRange, v) }
  static func error(_ v: AXError) -> AXValue { return create(.axError, v) }
}

extension NSScreen {
  static var primary: NSScreen? { screens.first }

  /// Converts the rectangle from Quartz "display space" to Cocoa "screen space".
  /// <http://stackoverflow.com/a/19887161/23649>
  static func convertFromQuartz(_ rect: CGRect) -> CGRect? {
    primary.map {
      var result = rect
      result.origin.y = $0.frame.maxY - result.maxY
      return result
    }
  }
}

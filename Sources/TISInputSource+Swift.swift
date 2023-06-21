import Foundation
import Carbon.HIToolbox.TextInputSources

extension TISInputSource {
  static var current: TISInputSource? {
    TISCopyCurrentKeyboardInputSource().takeUnretainedValue()
  }

  static var kaomoji: TISInputSource? {
    let bundleID = "local.kaomojipalette2.inputmethod.Kaomoji"
    let list = TISCreateInputSourceList([kTISPropertyBundleID: bundleID] as CFDictionary, true)
    return (list?.takeUnretainedValue() as? [Self])?.first
  }

  static var assistiveControl: TISInputSource? {
    let bundleID = "com.apple.inputmethod.AssistiveControl"
    let list = TISCreateInputSourceList([kTISPropertyBundleID: bundleID] as CFDictionary, true)
    return (list?.takeUnretainedValue() as? [Self])?.first
  }

  static func palettes(includeAllInstalled: Bool) -> [TISInputSource] {
    let list = TISCreateInputSourceList(
      [kTISPropertyInputSourceCategory: kTISCategoryPaletteInputSource] as CFDictionary,
      includeAllInstalled
    )
    return list?.takeUnretainedValue() as? [Self] ?? []
  }

  static func register(_ url: URL) {
    let result = TISRegisterInputSource(url as CFURL)
    if result != noErr { NSLog("TISRegisterInputSource error: \(result)") }
  }

  private func propertyValue<T>(forKey key: CFString) -> T? {
    guard let value = TISGetInputSourceProperty(self, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(value).takeUnretainedValue() as? T
  }

  var identifier: String? { propertyValue(forKey: kTISPropertyInputSourceID) }
  var bundleIdentifier: String? { propertyValue(forKey: kTISPropertyBundleID) }
  var iconImageURL: URL? { propertyValue(forKey: kTISPropertyIconImageURL) }

  var isEnabled: Bool? { propertyValue(forKey: kTISPropertyInputSourceIsEnabled) }
  var isEnableCapable: Bool? { propertyValue(forKey: kTISPropertyInputSourceIsEnableCapable) }
  var isSelectCapable: Bool? { propertyValue(forKey: kTISPropertyInputSourceIsSelectCapable) }

  func enable() {
    let result = TISEnableInputSource(self)
    if result != noErr { NSLog("TISEnableInputSource error: \(result)") }
  }

  func disable() {
    let result = TISDisableInputSource(self)
    if result != noErr { NSLog("TISDisableInputSource error: \(result)") }
  }

  func select() {
    let result = TISSelectInputSource(self)
    if result != noErr { NSLog("TISSelectInputSource error: \(result)") }
  }
  
  func deselect() {
    let result = TISDeselectInputSource(self)
    if result != noErr { NSLog("TISDeselectInputSource error: \(result)") }
  }
}

let kTISNotifyEnabledNonKeyboardInputSourcesChanged = "com.apple.Carbon.TISNotifyEnabledNonKeyboardInputSourcesChanged" as CFString

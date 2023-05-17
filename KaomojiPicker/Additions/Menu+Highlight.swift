import SwiftUI

extension Mirror {
  init(reflectingInnerContent subject: Any) {
    if let content = Mirror(reflecting: subject).descendant("content") {
      self.init(reflectingInnerContent: content)
    } else {
      self.init(reflecting: subject)
    }
  }
}

struct Menu<Content: View, Label: View>: NSViewRepresentable {
  @ViewBuilder var content: () -> Content
  @ViewBuilder var label: () -> Label

  func makeNSView(context: Context) -> NSSegmentedControl {
    let control = NSSegmentedControl(images: [NSImage()], trackingMode: .momentary, target: nil, action: nil)
    control.cell?.isBordered = false
    control.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    setImageAndMenu(control, context: context)
    return control
  }

  func updateNSView(_ control: NSSegmentedControl, context: Context) {
    setImageAndMenu(control, context: context)
  }

  func setImageAndMenu(_ control: NSSegmentedControl, context: Context) {
    let label = Mirror(reflectingInnerContent: label())
    let labelImageBundle = label.descendant("provider", "base", "location", "bundle") as? Bundle
    let labelImageName = label.descendant("provider", "base", "name") as? String ?? ""

    let labelImage: NSImage
    if let labelImageBundle {
      labelImage = labelImageBundle.image(forResource: labelImageName) ?? NSImage()
    } else {
      labelImage = NSImage(systemSymbolName: labelImageName, accessibilityDescription: nil) ?? NSImage()
    }

    let menu = NSMenu()
    if let content = Mirror(reflecting: content()).descendant("value") {
      for child in Mirror(reflecting: content).children {
        switch child.value {
        case is Divider:
          menu.addItem(.separator())

        case let button as Button<Text>:
          let button = Mirror(reflecting: button)

          let item = NSMenuItem()
          item.target = context.coordinator
          item.action = #selector(Coordinator.performAction(_:))

          if let text = button.descendant("label") as? Text {
            item.title = text._resolveText(in: context.environment)
          }

          if let action = button.descendant("action") as? () -> Void {
            item.representedObject = action
          }

          menu.addItem(item)

        default:
          break
        }
      }
    }

    control.setImage(labelImage, forSegment: 0)
    control.setMenu(menu, forSegment: 0)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator: NSObject {
    @objc func performAction(_ sender: NSMenuItem) {
      guard let action = sender.representedObject as? () -> Void else { return }
      action()
    }
  }
}

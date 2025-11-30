//
//  FocolistaApp.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

@main
struct FocolistaApp: App {
  @State private var clipboard: Clipboard = Clipboard()
  
  var body: some Scene {
    WindowGroup {
      WindowContainer()
        .environmentObject(clipboard)
    }.commands {
      CommandGroup(before: .pasteboard) {
        Button("Copiar referência") {
          NotificationCenter.default.post(
            name: .onCopyReferenceCommand,
            object: nil
          )
        }
        .keyboardShortcut("c", modifiers: [.option, .command])
      }
    }
  }
}

func saveWindowFrame(for window: NSWindow) {
  let frame = window.frame
  let dict: [String: CGFloat] = [
    "x": frame.origin.x,
    "y": frame.origin.y,
    "width": frame.size.width,
    "height": frame.size.height
  ]
  print("Fechando programa e salvando informações")
  UserDefaults.standard.set(dict, forKey: "janelaPrincipal.frame")
}

func loadWindowFrame(for window: NSWindow) {
  guard let dict = UserDefaults.standard.dictionary(forKey: "janelaPrincipal.frame") as? [String: CGFloat],
        let x = dict["x"], let y = dict["y"],
        let w = dict["width"], let h = dict["height"] else {
    return
  }
  
  let frame = NSRect(x: x, y: y, width: w, height: h)
  window.setFrame(frame, display: true)
}


struct WindowAccessor: NSViewRepresentable {
  var callback: (NSWindow?) -> Void
  
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      self.callback(view.window)
    }
    return view
  }
  
  func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
  func onWindowAvailable(_ callback: @escaping (NSWindow?) -> Void) -> some View {
    self.background(WindowAccessor(callback: callback))
  }
}

extension Notification.Name {
  static let onCopyReferenceCommand = Notification.Name("onCopyReferenceCommand")
}



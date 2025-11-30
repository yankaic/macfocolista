//
//  WindowContainer.swift
//  Focolista
//
//  Created by Yan Kaic on 23/11/25.
//
import SwiftUI

struct WindowContainer: View {
  @State private var navigation: [Task] = []
  @EnvironmentObject var clipboard: Clipboard

  var body: some View {
    Window(navigation: $navigation, clipboard: _clipboard)
      .onWindowAvailable { win in
        guard let win = win else { return }

        loadWindowFrame(for: win)

        NotificationCenter.default.addObserver(
          forName: NSWindow.willCloseNotification,
          object: win,
          queue: .main
        ) { _ in
          saveWindowFrame(for: win)
          Task.saveNavigation(stack: navigation)
        }
      }
  }
}

//
//  Clipboard.swift
//  Focolista
//
//  Created by Yan Kaic on 12/11/25.
//

import Foundation

enum ClipboardMode {
    case cut            // recortar
    case copy           // cópia normal (duplicar tarefas)
    case shortcut       // copiar referência (atalho)
    case none           // nada ativo
}

class Clipboard: ObservableObject {
  @Published var from: Task?
  @Published var tasks: [Task] = []
  @Published var mode: ClipboardMode = .none
  
  func clear() {
    from = nil
    tasks.removeAll()
    mode = .none
  }
  
  var isEmpty: Bool {
    mode == .none || tasks.isEmpty
  }
}


//
//  Clipboard.swift
//  Focolista
//
//  Created by Yan Kaic on 12/11/25.
//

enum ClipboardMode {
    case cut            // recortar
    case copy           // cópia normal (duplicar tarefas)
    case shortcut       // copiar referência (atalho)
    case none           // nada ativo
}

struct Clipboard {
  var from: Task?
  var tasks: [Task] = []
  var mode: ClipboardMode = .none
  
  mutating func clear() {
    from = nil
    tasks.removeAll()
    mode = .none
  }
  
  var isEmpty: Bool {
    mode == .none || tasks.isEmpty
  }
}


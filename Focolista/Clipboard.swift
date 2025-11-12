//
//  Clipboard.swift
//  Focolista
//
//  Created by Yan Kaic on 12/11/25.
//


struct Clipboard {
  var from: Task?
  var tasks: [Task] = []
  
  mutating func clear() {
    from = nil
    tasks.removeAll()
  }
  
  var isEmpty: Bool {
    tasks.isEmpty
  }
}

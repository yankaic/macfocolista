//
//  Tarefa.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//
import Foundation

struct Task: Identifiable, Hashable {
  let id: UUID
  var title: String
  var isCompleted: Bool
  
  init(id: UUID = UUID(), title: String, isCompleted: Bool) {
    self.id = id
    self.title = title
    self.isCompleted = isCompleted
  }  
}

//
//  Tarefa.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//
import Foundation

class Task {
  let id: UUID
  var title: String
  var description: String
  var isDone: Bool
  var subtasks: [Task]
  
  var onMark: [(Bool) -> Void] = []
  
  private var isSubtasksLoaded: Bool
  var isTemporary: Bool
  private var waitingSaveDescription: Bool = false
  
  private static var repository: MemoryRepository = MemoryRepository()
  
  init(title: String) {
    self.id = UUID()
    self.title = title
    self.description = ""
    self.isDone = false
    self.subtasks = []
    self.isSubtasksLoaded = false
    self.isTemporary = true
  }
  
  init(id: UUID, title: String, description: String, isDone: Bool){
    self.id = id
    self.title = title
    self.description = description
    self.isDone = isDone
    self.subtasks = []
    self.isSubtasksLoaded = false
    self.isTemporary = true
  }
  
  func save() {
    Task.repository.save(newtask: self)
    self.isTemporary = false
  }
  
  func loadSubtasks() {
    if (isSubtasksLoaded) {
      return
    }
    self.subtasks = Task.repository.loadSubtasks(for: self)
    self.isSubtasksLoaded = true
  }
  
  static func all() -> [Task] {
    return repository.all()
  }
  
  static func load(id: UUID) -> Task? {
    let task: Task? = Task.repository.load(taskId: id)
    if (task == nil){
      return nil
    }
    task!.isTemporary = false
    return task
  }
  
  func addSubtask(subtask: Task) {
    if (subtask.isTemporary) {
      Task.repository.save(newtask: subtask)
      subtask.isTemporary = false
    }
    Task.repository.addSubtask(task: self, subtask: subtask, position: self.subtasks.count)
  }
  
  func saveTitle() {
    Task.repository.rename(task: self)
  }
  
  func saveMark() {
    Task.repository.updateDone(task: self)
    for handle in onMark {
      handle(self.isDone)
    }
  }
  
  func saveDescription() {
    if (!self.waitingSaveDescription) {
      self.waitingSaveDescription = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        Task.repository.updateDescription(task: self)
        self.waitingSaveDescription = false
      }
    }
  }
  
}

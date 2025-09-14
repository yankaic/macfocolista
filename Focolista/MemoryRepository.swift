//
//  MemoryStorage.swift
//  Focolista
//
//  Created by Yan Kaic on 14/09/25.
//
import Foundation

class MemoryRepository {
  private let sqlite: SQLiteRepository = SQLiteRepository()
  private var cache: [UUID: Task] = [:]  // todas as tarefas, sejam raiz ou subtarefa
  
  
  /// Carrega uma tarefa isolada
  func load(taskId: UUID) -> Task? {
    if let cached = cache[taskId] {
      return cached
    }
    if let loaded = sqlite.load(taskId: taskId) {
      cache[loaded.id] = loaded
      return loaded
    }
    return nil
  }
  
  func all() -> [Task] {
    return sqlite.fetchAll()
  }
  
  /// Carrega as subtarefas de uma tarefa
  func loadSubtasks(for task: Task) -> [Task] {
    var subtasks: [Task] = []
    let loadedTasks = sqlite.loadSubtasks(task: task)
    
    // Ignorar tarefas do banco se já existir em cache
    for loaded in loadedTasks {
      if let cached = cache[loaded.id] {
        subtasks.append(cached)
      } else {
        loaded.isTemporary = false
        cache[loaded.id] = loaded
        subtasks.append(loaded)
      }
    }
    return subtasks
  }
  
  func save(newtask task: Task) {
    sqlite.insert(newtask: task)
    cache[task.id] = task
  }
  
  func addSubtask(task: Task, subtask: Task, position: Int) {
    sqlite.addSubtask(task: task, subtask: subtask, position: position)
    
  }
  
  func rename(task: Task){
    sqlite.rename(task: task)
  }
  
  func updateDone(task: Task){
    sqlite.updateDone(task: task)
  }
  
  func updateDescription(task: Task){
    sqlite.updateDescription(task: task)
    print("Salvando descrição às: " + DateFormatter().string(from: Date()))
  }
  
}

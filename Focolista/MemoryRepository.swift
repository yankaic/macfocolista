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
  
  init(){
    print("Inicializando o Memory Repository")
  }
  
  
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
    let loadedTasks = sqlite.fetchAll()
    return findInMemory(loadedTasks)
  }
  
  private func findInMemory(_ loadedTasks: [Task]) -> [Task] {
    var subtasks: [Task] = []
    // Ignorar tarefas do banco se já existir em cache
    for loaded in loadedTasks {
      if let cached = cache[loaded.id] {
        subtasks.append(cached)
        print("Tarefa encontrada em memória")
      } else {
        loaded.isTemporary = false
        cache[loaded.id] = loaded
        subtasks.append(loaded)
        print("Tarefa encontrada no banco: ")
      }
    }
    return subtasks
  }
  
  /// Carrega as subtarefas de uma tarefa
  func loadSubtasks(for task: Task) -> [Task] {
    let loadedTasks = sqlite.loadSubtasks(task: task)
    
    return findInMemory(loadedTasks)
  }
  
  func save(newtask task: Task) {
    if (task.isTemporary) {
      sqlite.insert(newtask: task)
      task.isTemporary = false
      cache[task.id] = task
    }
  }
  
  func addSubtask(task: Task, subtask: Task, position: Int) {
    save(newtask: subtask)
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

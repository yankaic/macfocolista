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
  

  private func findCaches(for tasks: [Task]) -> [Task] {
    return tasks.map { task in
      if let cached = cache[task.id] {
        print("cached: \(task.title)")
        return cached
      } else {
        cache[task.id] = task
        print("load: \(task.title)")
        return task
      }
    }
  }
  
  /// Atualiza do banco todas as tarefas do cache que ainda não foram persistidas.
  /// Após o carregamento, suas subtarefas são reconfiguradas para garantir
  /// que as referências usem as instâncias do cache.
  func load(ids: [Int]) -> [Task] {
    
    // Atualiza as tarefas a partir do banco de dados
    var tasks = sqlite.load(ids: ids)
    tasks = findCaches(for: tasks)
        
    tasks.forEach { task in
      loadSubtasks(task: task)
    }
    return tasks
  }
  
  func loadSubtasks(task: Task) {
    guard !task.isSubtasksLoaded else { return }
    sqlite.loadSubtasks(tasks: [task])
    task.subtasks = findCaches(for: task.subtasks)
    task.isSubtasksLoaded = true
  }
  
  func loadSubtasksLevel2(task: Task) {
    if (!task.isSubtasksLoaded) {
      loadSubtasks(task: task)
    }
    
    let subtasks : [Task] = task.subtasks
      .filter { return !$0.isSubtasksLoaded }
    
    //print("quantidade de subtarefas \(subtasks.count)")
    
    if subtasks.isEmpty { return }
    
    sqlite.loadSubtasks(tasks: subtasks)
    subtasks.forEach { subtask in
      subtask.subtasks = findCaches(for: subtask.subtasks)
    }
  }
  
  func addSubtask(task: Task, subtask: Task, position: Int) {
    sqlite.addSubtask(task: task, subtask: subtask, position: position)
  }
  

  func saveSubtasksOrder(task: Task){
    sqlite.saveSubtasksOrder(task: task)
  }
  
  func move(from: Task, destination: Task, subtasks: [Task]) {
    sqlite.move(from: from, destination: destination, subtasks: subtasks)
    sqlite.saveSubtasksOrder(task: from)
    sqlite.saveSubtasksOrder(task: destination)
  }
  
  func delete(parent: Task, subtask: Task) {
    sqlite.delete(parent: parent, subtask: subtask)
  }

  func save(newtask task: Task) {
    if (!task.isPersisted) {
      sqlite.insert(newtask: task)
      cache[task.id] = task
    }
  }
  
  func rename(task: Task){
    sqlite.rename(task: task)
  }
  
  func updateDone(task: Task){
    sqlite.updateDone(task: task)
  }
  
  func updateDescription(task: Task){
    sqlite.updateDescription(task: task)
    //print("Salvando descrição às: " + DateFormatter().string(from: Date()))
  }
  
  func map(uuid: UUID, int: Int){
    sqlite.mapping.save(uuid: uuid, int: int)
  }
  
  func saveNavigation(stack: [Task]) {
    sqlite.saveNavigation(stack: stack)
  }
  
  func loadNavigation() -> [Task] {
    var ids = sqlite.loadNavigation()
    if ids.isEmpty {
      ids = [1]
    }
    return load(ids: ids)
  }
}

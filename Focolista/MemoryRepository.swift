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
  
  /// Atualiza a lista de subtarefas de uma tarefa, mesclando com o cache existente.
  ///
  /// - Para cada subtarefa:
  ///   - Se já estiver no cache, usa a instância em cache (mantendo dados carregados).
  ///   - Se não estiver, adiciona ao cache e inclui na lista.
  /// A lista final sempre dá preferência às tarefas em cache.
  private func configureSubtasks(for task: Task) {
    task.subtasks = task.subtasks.map { subtask in
      if let cached = cache[subtask.id] {
        return cached
      } else {
        cache[subtask.id] = subtask
        return subtask
      }
    }
  }
  
  /// Atualiza do banco todas as tarefas do cache que ainda não foram persistidas.
  /// Após o carregamento, suas subtarefas são reconfiguradas para garantir
  /// que as referências usem as instâncias do cache.
  func load(ids: [Int]) -> [Task] {
    
    // Atualiza as tarefas a partir do banco de dados
    let tasks = sqlite.load(ids: ids)
    sqlite.loadSubtasks(tasks: tasks)
        
    tasks.forEach { task in
      cache[task.id] = task
      configureSubtasks(for: task)
    }
    return tasks
  }
  
  func loadSubtasks(task: Task) {
    guard !task.isSubtasksLoaded else { return }
    sqlite.loadSubtasks(tasks: [task])
    configureSubtasks(for: task)
  }
  
  func loadSubtasksLevel2(task: Task) {
    if (!task.isSubtasksLoaded) {
      loadSubtasks(task: task)
    }
    
    let subtasks : [Task] = task.subtasks
      .filter { return !$0.isSubtasksLoaded }
    
    print("quantidade de subtarefas \(subtasks.count)")
    
    if subtasks.isEmpty { return }
    
    sqlite.loadSubtasks(tasks: subtasks)
    subtasks.forEach { subtask in
      configureSubtasks(for: subtask)
    }
  }
  
  func addSubtask(task: Task, subtask: Task, position: Int) {
    save(newtask: subtask)
    sqlite.addSubtask(task: task, subtask: subtask, position: position)
  }
  

  func move(task: Task, from source: IndexSet, to destination: Int){
    sqlite.move(task: task, from: source, to: destination)
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
    print("Salvando descrição às: " + DateFormatter().string(from: Date()))
  }
  
  func map(uuid: UUID, int: Int){
    sqlite.mapping.save(uuid: uuid, int: int)
  }
  
  func saveNavigation(stack: [Task]) {
    sqlite.saveNavigation(stack: stack)
  }
  
}

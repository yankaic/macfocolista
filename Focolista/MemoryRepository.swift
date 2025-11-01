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
    if let task = sqlite.load(taskId: taskId) {
      cache[task.id] = task
      configureSubtasks(for: task)
      refreshUnpersistedTasks(tasks: task.subtasks)
      return task
    }
    return nil
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
  func refreshUnpersistedTasks(tasks: [Task]) {
    // Filtra apenas as tarefas ainda não persistidas
    let unpersisted = tasks.filter { !$0.isPersisted }
    guard !unpersisted.isEmpty else { return }
    
    // Atualiza as tarefas a partir do banco de dados
    sqlite.refresh(tasks: unpersisted)
    
    // Reconfigura as subtarefas com base no cache atualizado
    unpersisted.forEach { task in
      configureSubtasks(for: task)
    }
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
  
}

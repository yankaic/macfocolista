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
  
  var isPersisted: Bool
  var isSubtasksLoaded: Bool = false
  
  private var waitingSaveDescription: Bool = false
  private var waitingSaveTitle: Bool = false
  
  private static var repository: MemoryRepository = MemoryRepository()
  private static var navigationStack: [Task] = []
  
  init() {
    self.id = UUID()
    self.title = ""
    self.description = ""
    self.isDone = false
    self.subtasks = []
    self.isPersisted = false
  }
  
  init(title: String) {
    self.id = UUID()
    self.title = title
    self.description = ""
    self.isDone = false
    self.subtasks = []
    self.isPersisted = false
  }
  
  init(id: UUID) {
    self.id = id
    self.title = ""
    self.description = ""
    self.isDone = false
    self.subtasks = []
    self.isPersisted = false
  }
  
  init(id: UUID, title: String, description: String, isDone: Bool, subtasks: [Task]){
    self.id = id
    self.title = title
    self.description = description
    self.isDone = isDone
    self.subtasks = subtasks
    self.isPersisted = true
  }
  
  func save() {
    print(id.uuidString)
    Task.repository.save(newtask: self)
  }

  
  /// Carrega a pilha de navegação de tarefas armazenada nas preferências do usuário.
  ///
  /// Este método obtém a lista de identificadores inteiros salvos em `UserDefaults` sob a chave `"navigationStack"`.
  /// Cada identificador é mapeado para um `UUID`, que é então associado ao repositório de tarefas.
  /// Caso não exista uma pilha armazenada, a lista é inicializada com o identificador `1`.
  ///
  /// - Returns: A lista de tarefas correspondente à pilha de navegação atual.
  static func getNavigation() -> [Task] {
    print("Carregando pilha de navegação...")
    
    // Retorna imediatamente se já estiver carregada
    if !Task.navigationStack.isEmpty {
      return Task.navigationStack
    }
    
    // Obtém a lista de IDs inteiros salvos nas preferências
    let ids = [1]
    
    // Cria o mapeamento UUID <-> Int
    Task.navigationStack = Task.repository.load(ids: ids)
    return Task.navigationStack
  }
  
  func loadSubtasks(){
    print("Carregando subtarefas")
    Task.repository.loadSubtasksLevel2(task: self)
  }
  
  func addSubtask(subtask: Task, position: Int) {
    subtasks.insert(subtask, at: position)
    Task.repository.addSubtask(task: self, subtask: subtask, position: position)
  }
  
  func saveTitle() {
    if (!self.waitingSaveTitle) {
      self.waitingSaveTitle = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        Task.repository.rename(task: self)
        self.waitingSaveTitle = false
      }
    }
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

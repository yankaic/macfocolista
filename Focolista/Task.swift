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
  private static var navigationStack: [Task] = []
  
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
    print(id.uuidString)
    Task.repository.save(newtask: self)
    self.isTemporary = false
  }
  
  func loadSubtasks() {
    if (isSubtasksLoaded) {
      print("Subtarefas já carregadas")
      return
    }
    print("Subtarefas não carregas, então, carregando do banco")
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
  
  static func getNavigation() -> [Task] {
    print("Solicitada a informação da navegação")
    
    if Task.navigationStack.isEmpty {
      if let ids = UserDefaults.standard.stringArray(forKey: "navigationStack") {
        let tasks = ids.compactMap { idString -> Task? in
          guard let uuid = UUID(uuidString: idString) else { return nil }
          return Task.load(id: uuid)
        }
        Task.navigationStack = tasks
      }
    }
    
    if Task.navigationStack.isEmpty {
      print("Tratamento da lista vazia de navegação. Inserindo um item padrão (home)")
      if let homeIdString = UserDefaults.standard.string(forKey: "homeTask"),
         let homeId = UUID(uuidString: homeIdString),
         let home = Task.load(id: homeId) {
        Task.navigationStack.append(home)
      } else {
        let taskFake = Task(title: "Tarefa fake")
        Task.navigationStack.append(taskFake)
        print("⚠️ Nenhuma tarefa 'home' encontrada no banco ou no UserDefaults.")
      }
    }
    
    return Task.navigationStack
  }
  
  func addSubtask(subtask: Task) {
    
    Task.repository.addSubtask(task: self, subtask: subtask, position: self.subtasks.count)
    subtasks.append(subtask)
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

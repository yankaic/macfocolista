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

  static func loadNavigation() -> [Task] {
    print("Carregando pilha de navegação...")
    return Task.repository.loadNavigation()
  }
  
  static func saveNavigation(stack: [Task]) {
    Task.repository.saveNavigation(stack: stack)
  }
  
  func loadSubtasks(){
    print("Carregando subtarefas")
    Task.repository.loadSubtasksLevel2(task: self)
  }
  
  func addSubtask(subtask: Task, position: Int) {
    subtasks.insert(subtask, at: position)
    Task.repository.addSubtask(task: self, subtask: subtask, position: position)
    Task.repository.saveSubtasksOrder(task: self)    
  }
  
  func addSubtask(subtask: Task) {
    subtasks.append(subtask)
    Task.repository.addSubtask(task: self, subtask: subtask, position: subtasks.count)
  }
  
  func changeOrder(from source: IndexSet, to destination: Int){
    subtasks.move(fromOffsets: source, toOffset: destination)
    Task.repository.saveSubtasksOrder(task: self)
  }
  
  func move(from: Task, clipboard: [Task], position: Int) {
    subtasks.insert(contentsOf: clipboard, at: position)
    from.subtasks.removeAll { task in
      clipboard.contains{ $0.id == task.id }
    }
    Task.repository.move(from: from, destination: self, subtasks: clipboard)
  }
  
  func delete(subtask: Task) {
    if let position = subtasks.firstIndex(where: { $0.id == subtask.id }) {
      subtasks.remove(at: position)
      Task.repository.delete(parent: self, subtask: subtask)
      
      //Apenas para reposicionar as tarefas nos seus índices corretos.
      Task.repository.saveSubtasksOrder(task: self)
    }
  }

  
  func getCounterText() -> String{
    return "(\(subtasks.filter{ $0.isDone }.count)/\(subtasks.count))"
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

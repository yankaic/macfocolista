//
//  Tarefa.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//
import Foundation

class Task: Equatable{
  let id: UUID
  var title: String
  var description: String
  var isDone: Bool
  var subtasks: [Task]
  
  var isPersisted: Bool
  var isSubtasksLoaded: Bool = false
  
  var onMark: [UUID: (Bool) -> Void] = [:]
  var onDelete: [UUID: ([Task]) -> Void] = [:]
  
  private var waitingSaveDescription: Bool = false
  private var waitingSaveTitle: Bool = false
  
  private static var repository: MemoryRepository = MemoryRepository()
  private static var lastNavigation: [Task] = []
  
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
  
  init( title: String, description: String, isDone: Bool){
    self.id = UUID()
    self.title = title
    self.description = description
    self.isDone = isDone
    self.subtasks = []
    self.isPersisted = false
  }
  
  func save() {
    //print(id.uuidString)
    Task.repository.save(newtask: self)
  }

  static func loadNavigation() -> [Task] {
    if lastNavigation.isEmpty {
      print("Load navigation")
      lastNavigation = Task.repository.loadNavigation()
    }
    return lastNavigation
  }
  
  static func saveNavigationInMemory(stack: [Task]) {
    lastNavigation = stack
  }
  
  static func saveNavigation(stack: [Task]) {
    Task.repository.saveNavigation(stack: stack)
    lastNavigation = stack
  }
  
  func loadSubtasks(){
    Task.repository.loadSubtasksLevel2(task: self)
  }
  
  static func createClone(tasks: [Task]) -> [Task] {
    clones.removeAll()
    return tasks.map { $0.clone() }
  }
  
  private static var clones: [UUID: Task] = [:]
  private func clone() -> Task {
    if let cloned = Task.clones[id] {
      return cloned
    }
    let cloned = Task(title: title, description: description, isDone: false)
    cloned.save()
    Task.clones[id] = cloned
    loadSubtasks()
    let clonedSubtasks = subtasks.map { $0.clone() }
    clonedSubtasks.forEach { clonedSubtask in
      cloned.addSubtask(subtask: clonedSubtask)
    }
    return cloned
  }
  
  func addSubtask(subtask: Task, position: Int) {
    if(!subtask.isPersisted) {
      subtask.save()
    }
    subtasks.insert(subtask, at: position)
    Task.repository.addSubtask(task: self, subtask: subtask, position: position)
    Task.repository.saveSubtasksOrder(task: self)    
  }
  
  func addSubtask(subtask: Task) {
    if(!subtask.isPersisted) {
      subtask.save()
    }
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
    
    for (_, handle) in from.onDelete {
      handle(clipboard)
    }
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
  
  func saveMark(windowUUID: UUID) {
    Task.repository.updateDone(task: self)
    print("Marcando pelo usuário")
    for (uuid, handle) in onMark {
      if uuid == windowUUID {
        continue
      }
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
  
  func tooltip() -> String {
    return description.isEmpty ?
    title
    : "\(title)\n\n\(description)"
  }
  
  static func == (a: Task, b: Task) -> Bool {
    a.id == b.id
  }
  
}

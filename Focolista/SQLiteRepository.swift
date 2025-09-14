//
//  Database.swift
//  Focolista
//
//  Created by Yan Kaic on 11/09/25.
//

import SQLite
import Foundation

class SQLiteRepository {
  private let db: Connection
  
  private let tasksTable = Table("tasks")
  private let subtasksTable = Table("subtasks")
  
  private let idColumn = Expression<String>("id")
  private let titleColumn = Expression<String>("title")
  private let descriptionColumn = Expression<String>("description")
  private let isDoneColumn = Expression<Bool>("isCompleted")
  
  private let parentIdColumn = Expression<String>("task_id")
  private let subtaskIdColumn = Expression<String>("subtask_id")
  private let positionColumn = Expression<Int>("position")
  
  init() {
    let fileManager = FileManager.default
    let appSupport = try! fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    
    // cria uma pasta só da sua app, ex: ~/Library/Application Support/Focolista
    let appFolder = appSupport.appendingPathComponent("Focolista", isDirectory: true)
    if !fileManager.fileExists(atPath: appFolder.path) {
      try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
    }
    
    let dbPath = appFolder.appendingPathComponent("focolista.sqlite3").path
    
    do {
      db = try Connection(dbPath)
      //try db.run(tasksTable.drop(ifExists: true))
      try createTableIfNeeded()
    } catch {
      fatalError("Erro ao abrir banco: \(error)")
    }
  }
  
  private func createTableIfNeeded() throws {
    try db.run(tasksTable.create(ifNotExists: true) { table in
      table.column(idColumn, primaryKey: true)
      table.column(titleColumn)
      table.column(isDoneColumn)
      table.column(descriptionColumn)
    })
  }
  
  func load(taskId: UUID) -> Task? {
    do {
      if let row = try db.pluck(tasksTable.filter(idColumn == taskId.uuidString)) {
        return Task(
          id: UUID(uuidString: row[idColumn])!,
          title: row[titleColumn],
          description: row[descriptionColumn],
          isDone: row[isDoneColumn]
        )
      }
    } catch {
      print("Erro ao carregar tarefa: \(error)")
    }
    return nil
  }
  
  /// Carrega uma lista de subtarefas, passando uma tarefa mãe.
  /// - Parameter parentId: Tarefa mãe que possui as subtarefas
  /// - Returns: Retorna a lista de de subtarefas para ser adicionada na tarefa mãe em sua lista de subtarefas.
  func loadSubtasks(task: Task) -> [Task] {
    var subtasks: [Task] = []
    do {
      let query = subtasksTable
        .join(tasksTable, on: subtasksTable[subtaskIdColumn] == tasksTable[idColumn])
        .filter(subtasksTable[parentIdColumn] == task.id.uuidString)
        .order(subtasksTable[positionColumn].asc)
      
      for row in try db.prepare(query) {
        let task = Task(
          id: UUID(uuidString: row[tasksTable[idColumn]])!,
          title: row[tasksTable[titleColumn]],
          description: row[tasksTable[descriptionColumn]],
          isDone: row[tasksTable[isDoneColumn]]
        )
        subtasks.append(task)
      }
    } catch {
      print("Erro ao carregar subtarefas: \(error)")
    }
    return subtasks
  }
  
  func insert(newtask task: Task) {
    do {
      let insert = tasksTable.insert(
        idColumn <- task.id.uuidString,
        titleColumn <- task.title,
        isDoneColumn <- task.isDone,
        descriptionColumn <- task.description
      )
      try db.run(insert)
    } catch {
      print("Erro ao inserir: \(error)")
    }
  }
  
  func fetchAll() -> [Task] {
      do {
        return try db.prepare(tasksTable).map { row in
          Task(
            id: UUID(uuidString: row[idColumn]) ?? UUID(),
            title: row[titleColumn],
            description: row[descriptionColumn],
            isDone: row[isDoneColumn]
          )
        }
      } catch {
        print("Erro ao buscar: \(error)")
        return []
      }
    }
  
  
  func addSubtask(task: Task, subtask: Task, position: Int){
    do {
      let insert = subtasksTable.insert(
        parentIdColumn <- task.id.uuidString,
        subtaskIdColumn <- task.id.uuidString,
        positionColumn <- position
      )
      try db.run(insert)
    } catch {
      print("Erro ao inserir: \(error)")
    }
  }
  
  func rename(task: Task){
    do {
      let update = tasksTable
        .filter(idColumn == task.id.uuidString)
        .update(titleColumn <- task.title)
      try db.run(update)
    }
    catch {
      print("Erro ao atualizar título: \(error)")
    }
  }
  
  func updateDone(task: Task){
    do {
      let update = tasksTable
        .filter(idColumn == task.id.uuidString)
        .update(isDoneColumn <- task.isDone)
      try db.run(update)
      print("Marcação chamada pelo banco")
    }
    catch {
      print("Erro ao atualizar marcação: \(error)")
    }
  }
  
  func updateDescription(task: Task){
    do {
      let update = tasksTable
        .filter(idColumn == task.id.uuidString)
        .update(descriptionColumn <- task.description)
      try db.run(update)
    }
    catch {
      print("Erro ao atualizar descrição: \(error)")
    }
  }
}


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
  
  private static let formatter = DateFormatter()
  
  private let tasksTable = Table("tasks")
  private let subtasksTable = Table("subtasks")
  
  private let idColumn = Expression<String>("id")
  private let titleColumn = Expression<String>("title")
  private let descriptionColumn = Expression<String>("description")
  private let doneAtColumn = Expression<String>("doneAt")
  
  private let parentIdColumn = Expression<String>("parent_id")
  private let subtaskIdColumn = Expression<String>("subtask_id")
  private let positionColumn = Expression<Int>("position")
  
  private let createdAtColumn = Expression<String>("created_at")
  private let updatedAtColumn = Expression<String>("updated_at")
  private let deletedAtColumn = Expression<String>("deleted_at")
  
  init() {
    print("Inicializando o SQLite Repository")
    SQLiteRepository.formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
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
    print("Checando se tem tabela e criando se necessário")
    try db.run(tasksTable.create(ifNotExists: true) { table in
      table.column(idColumn, primaryKey: true)
      table.column(titleColumn)
      table.column(descriptionColumn)
      table.column(doneAtColumn)
      table.column(createdAtColumn)
      table.column(updatedAtColumn)
    })
    try db.run("""
      CREATE TABLE IF NOT EXISTS subtasks (
        parent_id TEXT NOT NULL,
        subtask_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        PRIMARY KEY (parent_id, subtask_id),
        FOREIGN KEY (parent_id) REFERENCES tasks(id) ON DELETE CASCADE,
        FOREIGN KEY (subtask_id) REFERENCES tasks(id) ON DELETE CASCADE
      );
    """)
    print("Checando se tem tarefas cadastradas no banco de dados")
    let count = (try? db.scalar("SELECT COUNT(*) FROM tasks") as? Int64) ?? 0
    if (count == 0) {
      print("Criando a primeira tarefa no banco de dados")
      try db.run("""
        INSERT INTO tasks values ('8B426F68-BED3-40F8-B2D1-DB080A3100B3', 'Focolista do banco', '', '', '', '');
      """)
      print("Tarefa salva")
      UserDefaults.standard.set("8B426F68-BED3-40F8-B2D1-DB080A3100B3", forKey: "homeTask")
      print("Identificador salvo em UserDefaults")
    }
  }
  
  private static func getStringDate() -> String {
    return SQLiteRepository.formatter.string(from: Date())
  }
  
  func load(taskId: UUID) -> Task? {
    do {
      if let row = try db.pluck(tasksTable.filter(idColumn == taskId.uuidString)) {
        return Task(
          id: UUID(uuidString: row[idColumn])!,
          title: row[titleColumn],
          description: row[descriptionColumn],
          isDone: row[doneAtColumn] != ""
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
          isDone: row[tasksTable[doneAtColumn]] != ""
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
        doneAtColumn <- task.isDone ? SQLiteRepository.getStringDate(): "",
        descriptionColumn <- task.description,
        createdAtColumn <- SQLiteRepository.getStringDate(),
        updatedAtColumn <- SQLiteRepository.getStringDate()
      )
      try db.run(insert)
      print("Criando nova tarefa: \(task.title)")
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
            isDone: row[doneAtColumn] != ""
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
        positionColumn <- position,
        createdAtColumn <- SQLiteRepository.getStringDate(),
        updatedAtColumn <- SQLiteRepository.getStringDate(),
        deletedAtColumn <- ""
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
        .update(titleColumn <- task.title,
                updatedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(update)
      print("Tarefa renomeada para: \(task.title)")
    }
    catch {
      print("Erro ao atualizar título: \(error)")
    }
  }
  
  func updateDone(task: Task){
    do {
      let doneAt = task.isDone ? SQLiteRepository.getStringDate(): ""
      let update = tasksTable
        .filter(idColumn == task.id.uuidString)
        .update(doneAtColumn <- doneAt,
                updatedAtColumn <- SQLiteRepository.getStringDate())
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
        .update(descriptionColumn <- task.description,
                updatedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(update)
    }
    catch {
      print("Erro ao atualizar descrição: \(error)")
    }
  }
}


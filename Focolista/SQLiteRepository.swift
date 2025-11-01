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
  
  private let idColumn = Expression<String>("id")
  private let titleColumn = Expression<String>("title")
  private let descriptionColumn = Expression<String>("description")
  private let doneAtColumn = Expression<String>("doneAt")
  private let subtasksColumn = Expression<String>("subtaks")
  
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
      db.trace { sql in
        print("SQL Executada: \(sql)")
      }
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
      table.column(subtasksColumn)
      table.column(createdAtColumn)
      table.column(updatedAtColumn)
    })
    print("Checando se tem tarefas cadastradas no banco de dados")
    let count = (try? db.scalar("SELECT COUNT(*) FROM tasks") as? Int64) ?? 0
    if (count == 0) {
      print("Criando a primeira tarefa no banco de dados")
      try db.run("""
        INSERT INTO tasks values ('8B426F68-BED3-40F8-B2D1-DB080A3100B3', 'Focolista do banco', '', '', '', '', '');
      """)
      print("Tarefa salva")
      UserDefaults.standard.set("8B426F68-BED3-40F8-B2D1-DB080A3100B3", forKey: "homeTask")
      print("Identificador salvo em UserDefaults")
    }
  }
  
  private static func getStringDate() -> String {
    return SQLiteRepository.formatter.string(from: Date())
  }
  
  /// Carrega uma tarefa específica do banco de dados a partir de seu UUID.
  ///
  /// Este método busca a tarefa correspondente no banco, inicializando seus atributos principais.
  /// As subtarefas são carregadas parcialmente, na qual, apenas seus identificadores (UUIDs) serão recuperados,
  /// permitindo um carregamento posterior mais eficiente.
  ///
  /// - Parameter taskId: O identificador único (`UUID`) da tarefa a ser carregada.
  /// - Returns: Um objeto `Task` completamente inicializado, ou `nil` se a tarefa não for encontrada.
  func load(taskId: UUID) -> Task? {
    do {
      guard let row = try db.pluck(tasksTable.filter(idColumn == taskId.uuidString)) else {
        print("Nenhuma tarefa encontrada com ID: \(taskId)")
        return nil
      }
      
      // Processa os identificadores das subtarefas (se houver)
      let subtaskIDs = row[subtasksColumn]
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .compactMap(UUID.init) // mantém apenas UUIDs válidos
      
      let subtasks = subtaskIDs.map { Task(id: $0) }
      
      // Garante que o UUID principal é válido antes de criar a Task
      guard let taskUUID = UUID(uuidString: row[idColumn]) else {
        print("ID inválido no registro da tarefa: \(row[idColumn])")
        return nil
      }
      
      return Task(
        id: taskUUID,
        title: row[titleColumn],
        description: row[descriptionColumn],
        isDone: !row[doneAtColumn].isEmpty,
        subtasks: subtasks
      )
    } catch {
      print("Erro ao carregar tarefa do banco de dados: \(error)")
      return nil
    }
  }
  
  /// Atualiza os atributos de uma lista de tarefas existentes com os dados mais recentes do banco de dados.
  ///
  /// Este método recebe uma lista mutável de `Task` e atualiza seus atributos com base
  /// nas informações armazenadas no banco. Somente os campos principais são carregados,
  /// enquanto as subtarefas são recuperadas parcialmente (apenas seus identificadores).
  ///
  /// - Parameter tasks: Lista de tarefas que serão atualizadas in-place.
  func refresh(tasks: [Task]) {
    guard !tasks.isEmpty else { return }
    
    do {
      // Coleta os IDs das tarefas informadas
      let idStrings = tasks.map { $0.id.uuidString }
      
      // Busca no banco todas as tarefas correspondentes
      let query = tasksTable.filter(idStrings.contains(idColumn))
      
      for row in try db.prepare(query) {
        guard let taskUUID = UUID(uuidString: row[idColumn]) else {
          print("Ignorando tarefa com ID inválido: \(row[idColumn])")
          continue
        }
        
        // Localiza a task correspondente na lista original
        guard let index = tasks.firstIndex(where: { $0.id == taskUUID }) else {
          print("Tarefa com ID \(taskUUID) não encontrada na lista fornecida.")
          continue
        }
        
        // Processa subtarefas (somente IDs)
        let subtaskIDs = row[subtasksColumn]
          .split(separator: ",")
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .compactMap(UUID.init)
        
        let subtasks = subtaskIDs.map { Task(id: $0) }
        
        // Atualiza os atributos da tarefa existente
        tasks[index].title = row[titleColumn]
        tasks[index].description = row[descriptionColumn]
        tasks[index].isDone = !row[doneAtColumn].isEmpty
        tasks[index].subtasks = subtasks
        tasks[index].isPersisted = true
      }
    } catch {
      print("Erro ao atualizar lista de tarefas: \(error)")
    }
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
      task.isPersisted = true
    } catch {
      print("Erro ao inserir: \(error)")
    }
  }
  
  func updateSubtasks(task: Task){
    let subtasksString = task.subtasks
      .map { $0.id.uuidString }
      .joined(separator: ",")
    do {
      let update = tasksTable
        .filter(idColumn == task.id.uuidString)
        .update(subtasksColumn <- task.title,
                updatedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(update)
      print("Lista de subtarefas atualizada")
    }
    catch {
      print("Erro ao atualizar título: \(error)")
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


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
  let mapping = UUIDMap()
  
  private static let formatter = DateFormatter()
  
  private let tasksTable = Table("tasks")
  private let subtasksTable = Table("edge")
  private let stackTable = Table("stack")
  
  private let idColumn = Expression<Int>("id")
  private let titleColumn = Expression<String>("title")
  private let descriptionColumn = Expression<String?>("description")
  private let doneAtColumn = Expression<String?>("completed_at")
    
  private let parentIdColumn = Expression<Int>("parent_id")
  private let taskIdColumn = Expression<Int>("task_id")
  private let subtaskIdColumn = Expression<Int>("child_id")
  private let positionColumn = Expression<Int>("position")
  
  private let createdAtColumn = Expression<String>("created_at")
  private let updatedAtColumn = Expression<String>("updated_at")
  private let deletedAtColumn = Expression<String?>("deleted_at")
  
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
    
    let dbPath = appFolder.appendingPathComponent("focolista.db").path
    
    do {
      db = try Connection(dbPath)
      //db.trace { sql in
        //print("SQL Executada: \(sql)")
      //}
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
      CREATE TABLE IF NOT EXISTS edge (
        parent_id INTEGER NOT NULL,
        subtask_id INTEGER NOT NULL,
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
    if let maxId = try db.scalar(tasksTable.select(idColumn.max)) {
        print("Maior ID: \(maxId)")
      mapping.setLastInt(value: maxId)
    }
    else {
      print("Criando a primeira tarefa no banco de dados")
      try db.run("""
        INSERT INTO tasks values (1, 'Focolista do banco', '', '', '', '');
      """)
      print("Tarefa salva")
      UserDefaults.standard.set(1, forKey: "homeTask")
      print("Identificador salvo em UserDefaults")
    }
  }
  
  private static func getStringDate() -> String {
    return SQLiteRepository.formatter.string(from: Date())
  }
  
  /// Atualiza os atributos de uma lista de tarefas existentes com os dados mais recentes do banco de dados.
  ///
  /// Este método recebe uma lista mutável de `Task` e atualiza seus atributos com base
  /// nas informações armazenadas no banco. Somente os campos principais são carregados,
  /// enquanto as subtarefas são recuperadas parcialmente (apenas seus identificadores).
  ///
  /// - Parameter tasks: Lista de tarefas que serão atualizadas in-place.
  /*func refresh(tasks: [Task]) {
    guard !tasks.isEmpty else { return }
    
    do {
      // Coleta os IDs das tarefas informadas
      let taskIDs = tasks.map { mapping.find(uuid: $0.id) }
      
      // Busca no banco todas as tarefas correspondentes
      let query = summaryTable.filter(taskIDs.contains(idColumn))
      
      for row in try db.prepare(query) {
        let taskUUID = mapping.find(int: row[idColumn])
        
        // Localiza a task correspondente na lista original
        guard let index = tasks.firstIndex(where: { $0.id == taskUUID }) else {
          print("Tarefa com ID \(taskUUID) não encontrada na lista fornecida.")
          continue
        }
        
        // Processa subtarefas (somente IDs)
        let subtasks = (row[subtasksColumn] ?? "")
          .split(separator: ",")
          .map { $0.trimmingCharacters(in: .whitespaces) }
          .compactMap(Int.init)
          .map{mapping.find(int: $0)}
          .map { Task(id: $0) }
        
        // Atualiza os atributos da tarefa existente
        tasks[index].title = row[titleColumn]
        tasks[index].description = row[descriptionColumn] ?? ""
        tasks[index].isDone = row[doneAtColumn] != nil
        tasks[index].subtasks = subtasks
        tasks[index].isPersisted = true
      }
    } catch {
      print("Erro ao atualizar lista de tarefas: \(error)")
    }
  }
   */
  
  func load(ids: [Int]) -> [Task] {
    var tasks: [Task] = []
    guard !ids.isEmpty else { return tasks }
    
    var taskMap: [Int: Task] = [:]
    
    tasks = ids.map { id in
      let uuid = mapping.find(int: id)
      let task = Task(id: uuid)
      taskMap[id] = task
      return task
    }
    
    // Dicionário para mapear tarefas principais
    do {
      let taskQuery = tasksTable.filter(ids.contains(idColumn))
      
      for row in try db.prepare(taskQuery) {
        let task = taskMap[row[idColumn]]!
        task.title = row[titleColumn]
        task.description = row[descriptionColumn] ?? ""
        task.isDone = row[doneAtColumn] != nil
        task.isPersisted = true
        //print("load: \(task.title)")
      }
    } catch {
      print("Erro ao atualizar lista de tarefas: \(error)")
    }
    return tasks
  }
  
  func loadSubtasks(tasks: [Task]) {
    guard !tasks.isEmpty else { return }
    
    var taskMap: [Int: Task] = [:]
    
    let intIDs = tasks.map { task in
      let id: Int = mapping.find(uuid: task.id)
      taskMap[id] = task      
      task.isSubtasksLoaded = true
      return id
    }
    do {
      let subtasksQuery = subtasksTable
        .join(tasksTable, on: subtaskIdColumn == tasksTable[idColumn])
        .filter(intIDs.contains(parentIdColumn) && deletedAtColumn == nil)
        .order(parentIdColumn, positionColumn)
      
      for row in try db.prepare(subtasksQuery) {
        let parentId = row[parentIdColumn]
        let childId = row[subtaskIdColumn]
        
        guard let task = taskMap[parentId] else { continue }
        
        
        let subtask = Task(id: mapping.find(int: childId))
        
        if task.subtasks.firstIndex(where: { $0.id == subtask.id }) != nil {
          continue
        }
        subtask.title = row[tasksTable[titleColumn]]
        subtask.description = row[tasksTable[descriptionColumn]] ?? ""
        subtask.isDone = row[tasksTable[doneAtColumn]] != nil
        subtask.isPersisted = true
        //print("load: \(subtask.title)")
        
        task.subtasks.append(subtask)
      }
    } catch {
      print("Erro ao atualizar lista de tarefas: \(error)")
    }
  }
  
  func insert(newtask task: Task) {
    do {
      let insert = tasksTable.insert(
        idColumn <- mapping.find(uuid: task.id),
        titleColumn <- task.title,
        doneAtColumn <- task.isDone ? SQLiteRepository.getStringDate(): nil,
        descriptionColumn <- task.description,
        createdAtColumn <- SQLiteRepository.getStringDate(),
        updatedAtColumn <- SQLiteRepository.getStringDate()
      )
      try db.run(insert)
      print("create: \(task.title)")
      task.isPersisted = true
    } catch {
      print("Erro ao inserir: \(error)")
    }
  }
  
  func addSubtask(task: Task, subtask: Task, position: Int){
    //updateSubtasks(task: task)
    
    do {
      let insert = subtasksTable.insert(
        parentIdColumn <- mapping.find(uuid: task.id),
        subtaskIdColumn <- mapping.find(uuid: subtask.id),
        positionColumn <- position,
        updatedAtColumn <- SQLiteRepository.getStringDate(),
        deletedAtColumn <- nil
      )
      try db.run(insert)
      print("subtask: \(task.title) → \(subtask.title)")
      task.isPersisted = true
    } catch {
      print("Erro ao inserir: \(error)")
    }
  }
  
  /// Reorganiza as posições das subtarefas de uma tarefa no banco de dados.
  ///
  /// Este método atualiza a posição (`position`) das subtarefas associadas a uma tarefa,
  /// refletindo a nova ordem definida na interface. As alterações são feitas dentro de uma
  /// transação SQLite para garantir consistência e performance.
  ///
  /// - Parameters:
  ///   - task: A tarefa mãe cujas subtarefas terão a posição atualizada.
  ///   - source: O conjunto de índices das subtarefas movidas.
  ///   - destination: O índice de destino para onde as subtarefas foram movidas.
  ///
  /// - Note: Este método assume que `task.subtasks` já foi reorganizada em memória,
  ///         por exemplo, através de `move(fromOffsets:toOffset:)` da API SwiftUI.
  ///         Ele apenas sincroniza a nova ordem com o banco de dados.
  ///
  func saveSubtasksOrder(task: Task) {
    do {
      // Inicia uma transação para garantir atomicidade
      try db.transaction {
        let parentID = mapping.find(uuid: task.id)
        
        // Atualiza as posições de todas as subtarefas na tabela "edge"
        for (position, subtask) in task.subtasks.enumerated() {
          let update = subtasksTable
            .filter(parentIdColumn == parentID && subtaskIdColumn == mapping.find(uuid: subtask.id))
            .update(positionColumn <- position + 1)
          try db.run(update)
          print("order: \(task.title) → \(position + 1) → \(subtask.title)")
        }
      }
      
    } catch {
      print("Erro ao reordenar subtarefas da tarefa \(task.id): \(error)")
    }
  }
  
  func move(from: Task, destination: Task, subtasks: [Task]) {
    do {
      let subtasksIDs = subtasks.map { mapping.find(uuid: $0.id) }
      let query = subtasksTable.filter(
        parentIdColumn == mapping.find(uuid: from.id)
        && subtasksIDs.contains(subtaskIdColumn)
        && deletedAtColumn == nil
      ).update(parentIdColumn <- mapping.find(uuid: destination.id))
      try db.run(query)
      print("from: \(from.title), to: \(destination.title), subtasks: \(subtasks.map(\.title).joined(separator: ", "))")
    }
    catch {
      print("Erro trocar tarefas de pai")
    }
  }
  
  /* 
  func updateSubtasks(task: Task){
    var subtasksString = ""
    if !task.subtasks.isEmpty {
      subtasksString = task.subtasks
        .map { $0.id.uuidString }
        .joined(separator: "\n")
    }
    
    do {
      let update = tasksTable
        .filter(idColumn == task.id.uuidString)
        .update(subtasksColumn <- subtasksString,
                updatedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(update)
      print("Lista de subtarefas atualizada")
    }
    catch {
      print("Erro ao atualizar título: \(error)")
    }
  }
  */
  
  func rename(task: Task){
    do {
      let update = tasksTable
        .filter(idColumn == mapping.find(uuid: task.id))
        .update(titleColumn <- task.title,
                updatedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(update)
      print("rename: \(task.title)")
    }
    catch {
      print("Erro ao atualizar título: \(error)")
    }
  }
  
  func updateDone(task: Task){
    do {
      let doneAt = task.isDone ? SQLiteRepository.getStringDate(): nil
      let update = tasksTable
        .filter(idColumn == mapping.find(uuid: task.id))
        .update(doneAtColumn <- doneAt,
                updatedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(update)
      print("mark: \(task.title)")
    }
    catch {
      print("Erro ao atualizar marcação: \(error)")
    }
  }
  
  func delete(parent: Task, subtask: Task) {
    do {
      let query = subtasksTable.filter(
        parentIdColumn == mapping.find(uuid: parent.id) &&
        subtaskIdColumn == mapping.find(uuid: subtask.id) &&
        deletedAtColumn == nil
      ).update(deletedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(query)
      print("Delete \(subtask.title)")
    }
    catch {
      print("Erro ao apagar: \(error)")
    }
  }
  
  func updateDescription(task: Task){
    do {
      let update = tasksTable
        .filter(idColumn == mapping.find(uuid: task.id))
        .update(descriptionColumn <- task.description,
                updatedAtColumn <- SQLiteRepository.getStringDate())
      try db.run(update)
    }
    catch {
      print("Erro ao atualizar descrição: \(error)")
    }
  }
  
  func saveNavigation(stack: [Task]) {
    do{
      try db.transaction {
        let delete = stackTable.delete()
        try db.run(delete)
                
        // Atualiza as posições de todas as subtarefas na tabela "edge"
        for (position, task) in stack.enumerated() {
          let update = stackTable.insert(
            taskIdColumn <- mapping.find(uuid: task.id),
            idColumn <- position + 1
          )
          try db.run(update)
        }        
        print("Save navigation")
      }
    }
    catch {
      print ("Não conseguiu atualizar a pilha de navegação")
    }
  }
  
  func loadNavigation() -> [Int] {
    do {
      var ids : [Int] = []
      for row in try db.prepare(stackTable) {
        ids.append(try row.get(taskIdColumn))
      }
      return ids
    } catch {
      print("deu algum erro no carregamento da navegação")
      return [1]
    }
  }
}


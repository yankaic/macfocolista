//
//  Database.swift
//  Focolista
//
//  Created by Yan Kaic on 11/09/25.
//

import SQLite
import Foundation

struct Database {
    static let shared = Database()
    private let db: Connection

    // Tabela
    private let tasks = Table("tasks")
    private let id = Expression<String>("id")
    private let title = Expression<String>("title")
    private let isCompleted = Expression<Bool>("isCompleted")

  private init() {
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
          try createTableIfNeeded()
      } catch {
          fatalError("Erro ao abrir banco: \(error)")
      }
  }


    private func createTableIfNeeded() throws {
        try db.run(tasks.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(title)
            t.column(isCompleted)
        })
    }

    func insert(task: Task) {
        do {
            let insert = tasks.insert(
                id <- task.id.uuidString,
                title <- task.title,
                isCompleted <- task.isCompleted
            )
            try db.run(insert)
        } catch {
            print("Erro ao inserir: \(error)")
        }
    }

    func fetchAll() -> [Task] {
        do {
            return try db.prepare(tasks).map { row in
                Task(
                    //id: UUID(uuidString: row[id]),
                    title: row[title],
                    isCompleted: row[isCompleted]
                )
            }
        } catch {
            print("Erro ao buscar: \(error)")
            return []
        }
    }
}

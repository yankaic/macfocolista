//
//  WindowView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct Window: View {
  @State private var task: Task = Task(title: "Linha inicial")
  @State private var subtasks: [Task] = []
  
  @State private var selection = Set<UUID>()
  @State private var windowTitle: String = "Focolista"
  @State private var description: String = ""
  
  // Focus: keeps track of the task currently being edited
  @FocusState private var editingTask: UUID?
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        List(selection: $selection) {
          NotesEditor(text: $description)
            .listRowSeparator(.hidden) //  remove o separador abaixo
          ForEach($subtasks, id: \.id) { $subtask in
            SubtaskView(
              onEnterSubtask: {
                windowTitle = subtask.title
              },
              onFinishEdit: {
                if subtask.title.isEmpty {
                  if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                    subtasks.remove(at: index)
                  }
                }
              },
              onEnterKeyPressed: {
                let newTask = Task(title: "")
                if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                  subtasks.insert(newTask, at: index + 1)
                } else {
                  subtasks.append(newTask)
                }
                selection = []
                editingTask = newTask.id
              },
              onStartEdit: {
                selection = []
              },
              onCommitNewTask: {
                if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                  task.addSubtask(subtask: subtask, position: index + 1)
                }
              },
              onToggleComplete: { newCompletedValue in
                //subtask.saveMark()
              },
              task: $subtask
            )
            .focused($editingTask, equals: subtask.id)
          }
          .onMove(perform: move)
          
          Button {
            let newTask = Task(title: "")
            subtasks.append(newTask)
            selection = []
            editingTask = newTask.id
          } label: {
            Label("Add task", systemImage: "plus")
              .foregroundColor(.accentColor)
          }
          .buttonStyle(.plain)
          .padding(.top, 8)
          
          // Espaço extra clicável
          Color.clear
            .frame(height: 10)
            .contentShape(Rectangle())
            .onTapGesture {
              selection.removeAll()
            }
            .listRowSeparator(.hidden)
        }
      }
    }
    .onAppear {
      print(Task(title: "Tarefa vazia só para iniciar").title)
      print("Método chamado ao iniciar a janela. É aqui que a tarefa deve ser carregada.")
      self.task = Task.getNavigation().last!
      print("Tarefa carregada: " + self.task.title)
      windowTitle = self.task.title
      description = self.task.description      
      subtasks = task.subtasks
    }
    .background(Color(NSColor.controlBackgroundColor))
    .navigationTitle(windowTitle)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button {
          // back button action
          self.windowTitle = "Focolista"
        } label: {
          Image(systemName: "chevron.left")
        }
      }
    }
  }
  private func move(from source: IndexSet, to destination: Int) {
    subtasks.move(fromOffsets: source, toOffset: destination)
  }
}

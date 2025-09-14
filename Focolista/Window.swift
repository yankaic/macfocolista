//
//  WindowView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct Window: View {
  @State private var subtasks: [Task] = Task.all()
  
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
          SubtasksView(
            subtasks: $subtasks,
            onEnterSubtask: { subtask in
              self.windowTitle = subtask.title
            },
            onFinishEdit: { subtask in
              selection = [subtask.id]
            },
            onStartEdit: { _ in
              selection = []
            },
            onToggleComplete: { subtask, completed in
              // Aqui você pode chamar o MemoryStorage/SQLiteStorage
              print("Task \(subtask.title) marcada como \(completed)")
            }
          )
            
            Button {
              let newTask = Task(title: "New task")
              subtasks.append(newTask)
              selection = []
              editingTask = newTask.id
              newTask.save()
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
}

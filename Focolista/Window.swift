//
//  WindowView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct Window: View {
  @State private var subtasks: [Task] = [
    Task(title: "Subtask list", isCompleted: true),
    Task(title: "Subtask reordering", isCompleted: true),
    Task(title: "Back button", isCompleted: true),
    Task(title: "Description field", isCompleted: true),
    Task(title: "New task input field", isCompleted: false),
    Task(title: "Description hint", isCompleted: false),
  ]
  
  @State private var selection = Set<UUID>()
  @State private var windowTitle: String = "Focolista"
  @State private var description: String = "Description"
  
  // Focus: keeps track of the task currently being edited
  @FocusState private var editingTask: UUID?
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        List(selection: $selection) {
          NotesEditor(text: $description)
            .listRowSeparator(.hidden) //  remove o separador abaixo
          ForEach($subtasks) { $subtask in
            SubtaskView(
              onEnterSubtask: {
                self.windowTitle = subtask.title
              },
              onFinishEdit: {
                selection = [subtask.id]
              },
              onStartEdit: {
                selection = []
              },
              task: $subtask
            )
            .focused($editingTask, equals: subtask.id)
          }
          .onMove(perform: move)
          // Botão Add Task (dentro da lista)
          addTaskButton
            .padding(.top, 8)          
          .buttonStyle(.plain)
          
          // Espaço clicável para limpar seleção
          Color.clear
            .frame(height: 60)
            .contentShape(Rectangle())
            .onTapGesture { selection.removeAll() }
            .listRowSeparator(.hidden)
        }
        addTaskButton
          .padding()
          //.background(.regularMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .shadow(radius: 3)
      }
    }
    .background(Color(NSColor.controlBackgroundColor))
    .navigationTitle(windowTitle)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button {
          self.windowTitle = "Focolista"
        } label: {
          Image(systemName: "chevron.left")
        }
      }
    }
  }
  
  private var addTaskButton: some View {
    Button {
      let newTask = Task(title: "New task", isCompleted: false)
      subtasks.append(newTask)
      selection.removeAll()
      editingTask = newTask.id
    } label: {
      Label("Add task", systemImage: "plus")
        .foregroundColor(.accentColor)
    }
  }
  
  private func move(from source: IndexSet, to destination: Int) {
    subtasks.move(fromOffsets: source, toOffset: destination)
  }
}

#Preview {
  Window()
}

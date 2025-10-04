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
          ForEach($subtasks, id: \.id ) { $subtask in
            SubtaskView(
              onEnterSubtask: {
                self.windowTitle = subtask.title
              },
              onFinishEdit: {
                selection = [subtask.id]
                subtask.saveTitle()
              },
              onStartEdit: {
                selection = []
              },
              onToggleComplete: { newCompletedValue in
                subtask.saveMark()
              },
              task: $subtask
            )
            .focused($editingTask, equals: subtask.id)
          }
          .onMove(perform: move)
          
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
  private func move(from source: IndexSet, to destination: Int) {
    subtasks.move(fromOffsets: source, toOffset: destination)
  }
}

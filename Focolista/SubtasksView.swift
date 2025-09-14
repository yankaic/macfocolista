//
//  SubtasksView.swift
//  Focolista
//
//  Created by Yan Kaic on 14/09/25.
//


import SwiftUI

struct SubtasksView: View {
  @Binding var subtasks: [Task]   // ← binding para poder mover os itens
  
  @FocusState var editingTask: UUID?
  
  var onEnterSubtask: (Task) -> Void
  var onFinishEdit: (Task) -> Void
  var onStartEdit: (Task) -> Void
  var onToggleComplete: (Task, Bool) -> Void
  
  var body: some View {
    ForEach($subtasks, id: \.id) { $subtask in
      SubtaskView(
        onEnterSubtask: { onEnterSubtask(subtask) },
        onFinishEdit: { onFinishEdit(subtask) },
        onStartEdit: { onStartEdit(subtask) },
        onToggleComplete: { completed in onToggleComplete(subtask, completed) },
        task: $subtask,
      ).focused($editingTask, equals: subtask.id)
      
    }
    .onMove(perform: move)
  }
  
  private func move(from source: IndexSet, to destination: Int) {
    subtasks.move(fromOffsets: source, toOffset: destination)
  }
}

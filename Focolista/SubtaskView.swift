//
//  TaskRowView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct SubtaskView: View {
  var onEnterSubtask: () -> Void
  var onFinishEdit: () -> Void
  var onEnterKeyPressed: () -> Void
  var onStartEdit: () -> Void
  var onCommitNewTask: () -> Void
  var onToggleComplete: (Bool) -> Void

  @Binding var task: Task
  @State private var title: String = ""
  @State private var counter: String = "(0/0)"
  @State private var showCounter: Bool = false
  @State private var isDone: Bool = false
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack {
      Toggle("", isOn: $isDone)
        .onChange(of: isDone) {
          //onToggleComplete(task.isDone)
          if isDone != task.isDone {
            task.isDone = isDone
            task.saveMark()
          }
        }

      TextField("Título da tarefa", text: $title)
        .onSubmit {
          if task.title != title {
            task.title = title
            if !task.isPersisted {
              onCommitNewTask()
            } else {
              task.saveTitle()
            }
          }
          onEnterKeyPressed()
        }
        .focused($isFocused)
        .onChange(of: isFocused) {
          if isFocused {
            onStartEdit()
          } else {
            onFinishEdit()
          }
        }
        .onChange(of: title){
          if (title != task.title) {
            task.title = title
            if !task.isPersisted {
              onCommitNewTask()
            } else {
              task.saveTitle()
            }
          }
        }
        .textFieldStyle(.plain)
        .onAppear {
          title = task.title
          isDone = task.isDone
          counter = task.getCounterText()
          showCounter = !task.subtasks.isEmpty

          task.onMark.append( { value in
            isDone = value
            print("Marcando por evento")
          })
        }

      Spacer()
      
      if showCounter {
        Text(counter)
          .opacity(0.35)
      }      

      Button(action: {
        onEnterSubtask()
      }) {
        Image(systemName: "chevron.right")
      }
      .buttonStyle(.borderless)
    }
    .padding(.vertical, 6)
  }
}

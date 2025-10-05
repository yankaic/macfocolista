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
  var onToggleComplete: (Bool) -> Void
  
  @Binding var task: Task
  @State private var title: String = ""
  @FocusState private var isFocused: Bool
  
  var body: some View {
    HStack {
      Toggle("", isOn: $task.isDone)
          .onChange(of: task.isDone) {
              onToggleComplete(task.isDone)
              task.saveMark()
          }
      
      TextField("Task title", text: $title)
        .onSubmit {
          if task.title != title {
            task.title = title
            if (task.isTemporary) {
              task.save()
            }
            else {
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
            if task.title != title {
              task.title = title
              if (task.isTemporary) {
                task.save()
              }
              else {
                task.saveTitle()
              }
            }  
          }
          onFinishEdit()
        }
        .textFieldStyle(.plain)
        .onAppear {
          title = task.title
          task.onMark.append( { value in
            task.isDone = value
            print("Marcando por aqui")
          }
                              
          )
          task.onMarkUnico = { booleano in
            //task.isDone = booleano
            print("Marcando tarefa ")
          }
        }
      
      Spacer()
      
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

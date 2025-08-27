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
  var onStartEdit: () -> Void
  @Binding var task: Task
  @State private var title: String = ""
  @FocusState private var isFocused: Bool
  
  var body: some View {
    HStack {
      Toggle("", isOn: $task.isCompleted)
        .toggleStyle(.checkbox)
        .labelsHidden()
      
      TextField("Task title", text: $title)
        .onSubmit {
          if task.title != title {
            task.title = title
            onFinishEdit()
          }
        }
        .focused($isFocused)
        .onChange(of: isFocused) {
          if isFocused {
            onStartEdit()
          } else {
            title = task.title
          }
        }
        .textFieldStyle(.plain)
        .onAppear {
          title = task.title
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

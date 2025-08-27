//
//  LinhaTarefaView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct SubtarefaView: View {
  var onEnterSubtask: () -> Void
  var onFinishEdit: () -> Void
  var onStartEdit: () -> Void
  @Binding var tarefa: Tarefa
  @State private var titulo: String = ""
  @FocusState private var isFocused: Bool
  
  var body: some View {
    HStack {
      Toggle("", isOn: $tarefa.concluida)
        .toggleStyle(.checkbox)
        .labelsHidden()
      
      TextField("Título da tarefa", text: $titulo)
        .onSubmit {
          if (tarefa.titulo != titulo) {
            tarefa.titulo = titulo
            onFinishEdit()
          }
        }
        .focused($isFocused)
        .onChange(of: isFocused) {
          if (isFocused) {
           onStartEdit()
          }
          else {
            titulo = tarefa.titulo
          }
        }
        .textFieldStyle(.plain)
        .onAppear {
          titulo = tarefa.titulo
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

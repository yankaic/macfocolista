//
//  LinhaTarefaView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct LinhaTarefaView: View {
    @Binding var tarefa: Tarefa
    @FocusState private var campoEmFoco: Bool
    @State private var tituloTemporario: String = ""

    var body: some View {
        HStack {
            Toggle("", isOn: $tarefa.concluida)
                .toggleStyle(.checkbox)
                .labelsHidden()

            TextField("", text: $tituloTemporario, onCommit: {
                tarefa.titulo = tituloTemporario
            })
            .textFieldStyle(.plain)
            .focused($campoEmFoco)
            .onAppear {
                tituloTemporario = tarefa.titulo
            }

            Spacer()

            Button(action: {
                print("Abrir tarefa: \(tarefa.titulo)")
            }) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}


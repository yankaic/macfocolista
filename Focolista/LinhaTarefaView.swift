//
//  LinhaTarefaView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct LinhaTarefaView: View {
    var tarefa: Tarefa
    var emEdicao: Bool
    var toggleConcluida: () -> Void
    var alterarTitulo: (String) -> Void
    var aoClicarBotao: () -> Void
    var aoIniciarEdicao: () -> Void
    var aoTerminarEdicao: () -> Void

    @State private var novoTitulo: String = ""

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { tarefa.concluida },
                set: { _ in toggleConcluida() }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            
            if emEdicao {
                TextField("", text: $novoTitulo, onCommit: {
                    alterarTitulo(novoTitulo)
                    aoTerminarEdicao()
                })
                .textFieldStyle(.plain)
                .onAppear {
                    novoTitulo = tarefa.titulo
                }
            } else {
                Text(tarefa.titulo)
                    .onTapGesture(count: 2) {
                        aoIniciarEdicao()
                    }
            }

            Spacer()

            Button(action: {
                aoClicarBotao()
            }) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}


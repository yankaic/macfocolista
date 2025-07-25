//
//  ContentView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct ConteudoPrincipal: View {
    @State private var tarefas: [Tarefa] = [
        Tarefa(titulo: "Tarefas para hoje", concluida: false),
        Tarefa(titulo: "Projetos", concluida: false),
        Tarefa(titulo: "Capacitação", concluida: true),
        Tarefa(titulo: "Chamados", concluida: false),
        Tarefa(titulo: "Estudar SwiftUI", concluida: false)
    ]
    
    @State private var selecao = Set<UUID>()

    var body: some View {
        List(selection: $selecao) {
            ForEach(tarefas) { tarefa in
                HStack {
                    Toggle(isOn: binding(para: tarefa)) {
                        Text(tarefa.titulo)
                    }
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    
                    Text(tarefa.titulo)
                    
                    Spacer()
                    
                    Button(action: {
                        // Ação do botão ">"
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
            .onMove(perform: mover)
        }
        .listStyle(.inset)
    }

    private func mover(de origem: IndexSet, para destino: Int) {
        tarefas.move(fromOffsets: origem, toOffset: destino)
    }

    private func binding(para tarefa: Tarefa) -> Binding<Bool> {
        guard let indice = tarefas.firstIndex(of: tarefa) else {
            return .constant(tarefa.concluida)
        }
        return $tarefas[indice].concluida
    }
}

#Preview {
    ConteudoPrincipal()
}

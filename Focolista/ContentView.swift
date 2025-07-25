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
    @State private var tituloJanela: String = "Focolista"
    @State private var edicoes = Set<UUID>()

    var body: some View {
        NavigationStack {
            List(selection: $selecao) {
                ForEach(tarefas) { tarefa in
                    LinhaTarefaView(
                        tarefa: tarefa,
                        emEdicao: edicoes.contains(tarefa.id),
                        toggleConcluida: {
                            if let index = tarefas.firstIndex(of: tarefa) {
                                tarefas[index].concluida.toggle()
                            }
                        },
                        alterarTitulo: { novoTitulo in
                            if let index = tarefas.firstIndex(of: tarefa) {
                                tarefas[index].titulo = novoTitulo
                            }
                        },
                        aoClicarBotao: {
                            tituloJanela = tarefa.titulo
                        },
                        aoIniciarEdicao: {
                            edicoes.insert(tarefa.id)
                        },
                        aoTerminarEdicao: {
                            edicoes.remove(tarefa.id)
                        }
                    )
                }
                .onMove(perform: mover)
            }
            .listStyle(.inset)
        }
        .navigationTitle(tituloJanela)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    tituloJanela = "Focolista"
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func mover(de origem: IndexSet, para destino: Int) {
        tarefas.move(fromOffsets: origem, toOffset: destino)
    }
}

#Preview {
    ConteudoPrincipal()
}

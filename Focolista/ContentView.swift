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

    var body: some View {
            NavigationSplitView {
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
                                tituloJanela = tarefa.titulo
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
            } detail: {
                Text("Conteúdo detalhado aqui")
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
                
                ToolbarItem(placement: .principal) {
                    Text(tituloJanela)
                        .font(.headline)
                }
            }
            .frame(minWidth: 400, minHeight: 300)
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

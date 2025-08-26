//
//  Janela.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct Janela: View {
  @State private var subtarefas: [Tarefa] = [
    Tarefa(titulo: "Lista de subtarefas", concluida: true),
    Tarefa(titulo: "Reordenação de subtarefa", concluida: true),
    Tarefa(titulo: "Botão de voltar", concluida: true),
    Tarefa(titulo: "Campo de descrição", concluida: true),
    Tarefa(titulo: "Campo de entrada de nova tarefa", concluida: false),
    Tarefa(titulo: "Dica de descrição", concluida: false),
  ]

  @State private var selecao = Set<UUID>()
  @State private var tituloJanela: String = "Focolista"
  @State private var descricao: String = "Descricao"

  var body: some View {
    NavigationStack {
        VStack (spacing: 0){
            NotesEditor(text: $descricao)
            List(selection: $selecao) {
              ForEach($subtarefas) { $subtarefa in
                SubtarefaView(
                  onEnterSubtask: {
                    self.tituloJanela = subtarefa.titulo
                  }, tarefa: $subtarefa
                )
              }
              .onMove(perform: mover)
                Button {
                    print("Botão 'Adicionar Tarefa' foi apertado")
                } label: {
                    Label("Adicionar tarefa", systemImage: "plus")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        //.background(.white)
      .navigationTitle(tituloJanela)
      .toolbar {
        ToolbarItem(placement: .navigation) {
          Button {
            //ação do botão voltar
            self.tituloJanela = "Focolista"
          } label: {
            Image(systemName: "chevron.left")
          }
        }
      }
    }
  }

  private func mover(de origem: IndexSet, para destino: Int) {
    subtarefas.move(fromOffsets: origem, toOffset: destino)
  }
}

#Preview {
  Janela()
}

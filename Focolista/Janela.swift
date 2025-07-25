//
//  Janela.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct Janela: View {
  @State private var subtarefas: [Tarefa] = [
    Tarefa(titulo: "Tarefas para hoje", concluida: false),
    Tarefa(titulo: "Projetos", concluida: false),
    Tarefa(titulo: "Capacitação", concluida: true),
    Tarefa(titulo: "Chamados", concluida: false),
    Tarefa(titulo: "Estudar SwiftUI", concluida: false),
  ]

  @State private var selecao = Set<UUID>()
  @State private var tituloJanela: String = "Focolista"

  var body: some View {
    NavigationStack {
      List(selection: $selecao) {
        ForEach($subtarefas) { $subtarefa in
          SubtarefaView(
            onEnterSubtask: {
              self.tituloJanela = subtarefa.titulo
            }, tarefa: $subtarefa
          )

        }
        .onMove(perform: mover)
      }
      .listStyle(.inset)
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
    }.frame(width: 300, height: 250)
  }

  private func mover(de origem: IndexSet, para destino: Int) {
    subtarefas.move(fromOffsets: origem, toOffset: destino)
  }
}

#Preview {
  Janela()
}

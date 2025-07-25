//
//  TesteView.swift
//  Focolista
//
//  Created by Yan Kaic on 21/07/25.
//
import SwiftUI
struct TesteView: View {
    // Dados da lista
    let names = ["Ana", "Bruno", "Carlos", "Daniela", "Eduardo", "Fernanda"]
    
    // Estado para armazenar os itens selecionados
    @State private var selectedItems = Set<String>()
    
    var body: some View {
        VStack {
            // Lista com seleção múltipla
            List(names, id: \.self, selection: $selectedItems) { name in
                Text(name)
                    .onDoubleClick { print("Double click detected") }
                    .contextMenu {
                        // Menu contextual opcional
                        Button("Imprimir nome") {
                            print("Menu contextual: \(name)")
                        }
                    }
            }
            .frame(minWidth: 100, minHeight: 100)
            
            // Mostrar itens selecionados (opcional)
            Text("Selecionados: \(selectedItems.count)")
                .padding()
        }
        .frame(width: 300, height: 300)
    }
}

// Pré-visualização
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TesteView()
    }
}

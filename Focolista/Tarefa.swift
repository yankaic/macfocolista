//
//  Tarefa.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//
import Foundation

struct Tarefa: Identifiable, Hashable {
    let id = UUID()
    var titulo: String
    var concluida: Bool
    var emEdicao: Bool = false // ← NOVO: controla se a tarefa está sendo editada

}

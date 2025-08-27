//
//  Tarefa.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//
import Foundation

struct Tarefa: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var isCompleted: Bool

}

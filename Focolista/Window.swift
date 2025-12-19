//
//  WindowView.swift
//  Focolista
//
//  Created by Yan Kaic on 20/07/25.
//

import SwiftUI

struct Window: View {
  @State private var task: Task? = nil
  @State private var subtasks: [Task] = []
  
  @State private var selection = Set<UUID>()
  @State private var windowTitle: String = "Focolista"
  @State private var description: String = ""
  
  @State private var navigation: [Task] = []
  @EnvironmentObject var clipboard: Clipboard
  @State private var nsWindow: NSWindow?
  @State private var windowUUID: UUID = UUID()
  
  @State private var showNotes: Bool = false
  @State private var scrollTarget: UUID?
  @State private var lastTask: UUID?
  
  // Focus: keeps track of the task currently being edited
  @FocusState private var editingTask: UUID?
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          List(selection: $selection) {
            if showNotes {
              NotesEditor(text: $description, task: $task)
                .listRowSeparator(.hidden) //  remove o separador abaixo
                .focused($editingTask, equals: windowUUID)
            }
            ForEach($subtasks, id: \.id) { $subtask in
              SubtaskView(
                onEnterSubtask: {
                  navigation.append(subtask)
                  enter(task: subtask)
                },
                onFinishEdit: {
                  if subtask.title.isEmpty {
                    if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                      subtasks.remove(at: index)
                    }
                  }
                },
                onEnterKeyPressed: {
                  let newTask = Task(title: "")
                  if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                    subtasks.insert(newTask, at: index + 1)
                  } else {
                    subtasks.append(newTask)
                  }
                  selection = []
                  editingTask = newTask.id                  
                  lastTask = newTask.id
                },
                onStartEdit: {
                  selection.removeAll()
                },
                onCommitNewTask: {
                  if let position = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                    if(position == (subtasks.count - 1)){
                      task?.addSubtask(subtask: subtask)
                    }
                    else {
                      task?.addSubtask(subtask: subtask, position: position)
                    }
                  }
                },
                onToggleComplete: { newCompletedValue in
                  selection.removeAll()
                },
                windowUUID: self.windowUUID,
                task: $subtask
              )
              .focused($editingTask, equals: subtask.id)
              .help("\(subtask.title)\n\n\(subtask.description)")
            }
            .onMove(perform: move)
            
            Button {
              let newTask = Task(title: "")
              subtasks.append(newTask)
              selection = []
              editingTask = newTask.id
            } label: {
              Label("Adicionar nova tarefa", systemImage: "plus")
                .foregroundColor(.accentColor)
                .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            // Espaço extra clicável
            Color.clear
              .frame(height: 10)
              .contentShape(Rectangle())
              .onTapGesture {
                selection.removeAll()
              }
              .listRowSeparator(.hidden)
          }
          .onChange(of: scrollTarget) { _, target in
            guard let target else { return }
            proxy.scrollTo(target, anchor: .center)
          }
          .onChange(of: lastTask) { _, target in
            guard let target else { return }
            withAnimation {
              proxy.scrollTo(target, anchor: .center)
            }
          }
          .onDeleteCommand {
            // Filtra as subtarefas que estão selecionadas
            let selecionadas = subtasks.filter { selection.contains($0.id) }
            
            // Para cada subtarefa selecionada, chama o método de remoção da Task principal
            for subtask in selecionadas {
              task!.delete(subtask: subtask)
            }
            
            // Remove as subtarefas também da lista local (para atualizar a UI)
            subtasks.removeAll { selection.contains($0.id) }
            
            // Limpa a seleção após remover
            selection.removeAll()
          }
          .onCopyCommand {
            let selecionadas = subtasks.filter { selection.contains($0.id) }
            let texto = selecionadas.map(\.title).joined(separator: "\n")
            print ("Selecionada a opção de copiar")
            clipboard.mode = .copy
            clipboard.tasks = selecionadas
            return [NSItemProvider(object: texto as NSString)]
          }
          .onCutCommand {
            let selecionadas = subtasks.filter { selection.contains($0.id) }
            let texto = selecionadas.map(\.title).joined(separator: "\n")
            print ("Selecionada a opção de recortar")
            clipboard.mode = .cut
            clipboard.from = task
            clipboard.tasks = selecionadas
            return [NSItemProvider(object: texto as NSString)]
          }
          .onReceive(NotificationCenter.default.publisher(for: .onCopyReferenceCommand)) { _ in
            guard let win = nsWindow, win.isKeyWindow else { return }
            let selecionadas = subtasks.filter { selection.contains($0.id) }
            clipboard.mode = .shortcut
            clipboard.from = task
            clipboard.tasks = selecionadas
            print ("modo atalho: \(selecionadas.map(\.title).joined(separator: ","))")
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(selecionadas.map(\.title).joined(separator: "\n"), forType: .string)
          }
          .onPasteCommand(of: [.text]) { itemProviders in
            if !clipboard.isEmpty {
              print ("Tarefas da área de transferência: \(clipboard.tasks.map(\.title).joined(separator: "\n"))")
              var position = 0
              if let indice = subtasks.firstIndex(where: { selection.contains($0.id) }) {
                print("Posição do local a colar: \(indice)")
                position = indice
              } else {
                print("Não há seleção na tela. Colando no final das tarefas")
                position = subtasks.count
              }
              switch clipboard.mode {
              case .copy:
                print("Colando clones")
                clipboard.tasks = Task.createClone(tasks: clipboard.tasks)
                var index = position
                clipboard.tasks.forEach { newSubtask in
                  task?.addSubtask(subtask: newSubtask, position: index)
                  index += 1
                }
                
              case .cut:
                let blockPaste = clipboard.tasks.contains { a in
                  navigation.contains { b in
                        a.id == b.id
                    }
                }
                if blockPaste {
                    return
                }
                position -= task!.subtasks.prefix(position).filter { clipboard.tasks.contains($0) }.count
                task?.move(from: clipboard.from!, clipboard: clipboard.tasks, position: position)
                
              case .shortcut:
                if task?.id == clipboard.from?.id {
                  return
                }
                var index = position
                clipboard.tasks.forEach { newSubtask in
                  task?.addSubtask(subtask: newSubtask, position: index)
                  index += 1
                }
                
              case .none:
                break
              }
              subtasks.insert(contentsOf: clipboard.tasks, at: position)
              selection.removeAll()
              selection.formUnion(clipboard.tasks.map(\.id))
              clipboard.clear()
              return
            }
            for provider in itemProviders {
              _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                if let texto = object as? String {
                  DispatchQueue.main.async {
                    let novas = texto
                      .split(separator: "\n")
                      .map { Task(title: String($0)) }
                    novas.forEach { newSubtask in
                      task?.addSubtask(subtask: newSubtask)
                    }
                    subtasks.append(contentsOf: novas)
                    selection.removeAll()
                    selection.formUnion(novas.map(\.id))
                  }
                }
              }
            }
          }
        }
      }
    }
    .padding(.top, -5)
    .onAppear {
      print("Iniciando janela")
      navigation = Task.loadNavigation()
      let task = navigation.last!
      enter(task: task)
    }
    .onWindowAvailable { win in
      guard let win = win else { return }
      self.nsWindow = win
      //win.level = .floating
      
      loadWindowFrame(for: win)
      
      NotificationCenter.default.addObserver(
        forName: NSWindow.willCloseNotification,
        object: win,
        queue: .main
      ) { _ in
        subtasks.forEach { subtask in
          subtask.onMark.removeValue(forKey: windowUUID)
        }
        saveWindowFrame(for: win)
        Task.saveNavigation(stack: navigation)
      }
    }
    .background(Color(NSColor.controlBackgroundColor))
    .navigationTitle(windowTitle)
    .toolbarBackground(.windowBackground, for: .windowToolbar)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button {
          if navigation.count > 1 {
            let from = navigation.popLast()!
            let parent = navigation.last!
            enter(task: parent)
            selection = [from.id]
            scrollTarget = from.id
          }
        } label: {
          Image(systemName: "chevron.left")
        }
      }
      if (!showNotes){
        ToolbarItem(placement: .primaryAction) {
          Button {
            self.showNotes = true
            self.editingTask = windowUUID
          } label: {
            Image(systemName: "square.and.pencil")
          }
          .help("Adicionar descrição")
        }
      }
    }
  }
  
  private func enter(task: Task) {
    subtasks.forEach { subtask in
      subtask.onMark.removeValue(forKey: windowUUID)
    }
    self.task?.onDelete.removeValue(forKey: windowUUID)
    self.task = task
    print("Focus: " + task.title)
    windowTitle = task.title
    description = task.description
    task.loadSubtasks()
    subtasks = task.subtasks
    
    if !subtasks.isEmpty {
      scrollTarget = subtasks[0].id
    }
    
    task.onDelete[windowUUID] = { tasksExited in
      subtasks.removeAll { subtask in
        tasksExited.contains{ $0.id == subtask.id }
      }
    }
    self.showNotes = !task.description.isEmpty
    Task.saveNavigationInMemory(stack: self.navigation)
  }
  private func move(from source: IndexSet, to destination: Int) {
    subtasks.move(fromOffsets: source, toOffset: destination)
    self.task?.changeOrder(from: source, to: destination)
  }
}

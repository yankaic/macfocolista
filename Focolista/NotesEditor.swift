import SwiftUI

struct NotesEditor: View {
  @Binding var text: String
  @Binding var task: Task
  let paddingTextEditor: CGFloat = 8
  @State private var dynamicHeight: CGFloat = 0  // initial estimated height for a single line
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      //Texto invisível apenas para cálculo
      Text(text)
        .foregroundColor(.clear)
      //.foregroundColor(.red)
        .padding(.horizontal, 0)
        .padding(.bottom, paddingTextEditor)
        .background(
          GeometryReader { geometry in
            Color.clear
              .onAppear {
                dynamicHeight = geometry.size.height
              }
              .onChange(of: text) {
                dynamicHeight = geometry.size.height + paddingTextEditor
                task.description = text
                task.saveDescription()
              }
          }
        )
      
      if text.isEmpty {
        Text("Descrição")
          .opacity(0.35)
          .padding(.horizontal, 0)
          .padding(.bottom, paddingTextEditor)
      }
      
      // Visible text editor
      TextEditor(text: $text)
        .font(.body)
        .opacity(0.65)
        .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
        .scrollDisabled(true)
        .textEditorStyle(.plain)
        .padding(.horizontal, -5)
        .padding(.bottom, paddingTextEditor * -1)
    }
    .background(Color(NSColor.controlBackgroundColor))
  }
}

import SwiftUI

struct NotesEditor: View {
  @Binding var text: String
  @Binding var task: Task?
  let paddingTextEditor: CGFloat = 8
  @State private var dynamicHeight: CGFloat = 0  // initial estimated height for a single line
  @FocusState private var isFocused: Bool
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      //Texto invisível apenas para cálculo
      Text(text)
        .foregroundColor(.clear)
        .font(.system(size: 14))
      //.foregroundColor(.red)
        .padding(.horizontal, 0)
        .padding(.bottom, paddingTextEditor)
        .background(
          GeometryReader { geometry in
            Color.clear
              .onAppear {
                dynamicHeight = geometry.size.height
              }
              .onChange(of: geometry.size) {
                dynamicHeight = geometry.size.height + paddingTextEditor
              }
              .onChange(of: text) {
                dynamicHeight = geometry.size.height + paddingTextEditor
                task?.description = text
                task?.saveDescription()
              }
          }
        )
      
      if text.isEmpty {
        Text("Descrição")
          .opacity(0.35)
          .padding(.horizontal, 0)
          .padding(.bottom, paddingTextEditor)
          .font(.system(size: 14))
      }
      
      // Visible text editor
      TextEditor(text: $text)
        .font(.system(size: 14))
        .opacity(0.65)
        .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
        .scrollDisabled(true)
        .textEditorStyle(.plain)
        .padding(.horizontal, -5)
        .padding(.bottom, paddingTextEditor * -1)
        .focused($isFocused)
    }
    .padding(.top, 5)
    .background(Color(NSColor.controlBackgroundColor))
  }
}

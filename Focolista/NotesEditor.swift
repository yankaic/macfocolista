import SwiftUI

struct NotesEditor: View {
    @Binding var text: String
    @State private var dynamicHeight: CGFloat = 0  // initial estimated height for a single line

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Invisible height measurer
            Text(text)
                .foregroundColor(.clear)
                .padding(.horizontal, 18)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                dynamicHeight = geometry.size.height
                            }
                            .onChange(of: text) {
                                dynamicHeight = geometry.size.height
                            }
                    }
                )

            // Visible text editor
            TextEditor(text: $text)
                .font(.body)
                .opacity(0.65)
                .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
                .scrollDisabled(true)
                .textEditorStyle(.plain)
                .padding(.horizontal, 0)
                .padding(.bottom, 10)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}


import SwiftUI

struct NotesEditor: View {
    @Binding var text: String
    @State private var dynamicHeight: CGFloat = 0  // altura inicial estimada para uma linha

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Medidor invisível de altura
            Text(text)
                .foregroundColor(.clear)
                .padding(.horizontal, 18)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                dynamicHeight = geometry.size.height
                            }
                            .onChange(of: text){ _ in
                                dynamicHeight = geometry.size.height
                            }
                    }
                )

            // Editor de texto visível
            TextEditor(text: $text)
                .font(.body)
                .opacity(0.65)
                .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
                .scrollDisabled(true)
                .textEditorStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.top, 15)
        }
        .background(Color.init(NSColor.controlBackgroundColor))
    }
}


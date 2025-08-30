import SwiftUI

struct ScrollTeste: View {
    @State private var showFixedSpecialItem = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack() {
                    ForEach(0..<39, id: \.self) { index in
                        Text("Item \(index + 1)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }

                    SpecialItemView(showFixedSpecialItem: $showFixedSpecialItem)
                }
                .padding()
            }

            if showFixedSpecialItem {
                Text("Item Especial (Clone)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showFixedSpecialItem)
            }
        }
    }
}

struct SpecialItemView: View {
    @Binding var showFixedSpecialItem: Bool

    var body: some View {
        GeometryReader { geo in
            Text("Item Especial")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(8)
                .onAppear {
                    updateVisibility(frame: geo.frame(in: .global))
                }
                .onChange(of: geo.frame(in: .global)) { newFrame in
                    updateVisibility(frame: newFrame)
                }
        }
        .frame(height: 50)
    }

  private func updateVisibility(frame: CGRect) {
      DispatchQueue.main.async {
          if let screenFrame = NSScreen.main?.visibleFrame {
              let topVisibleY = screenFrame.minY
              let bottomVisibleY = screenFrame.maxY

              let isFullyVisible = frame.minY >= topVisibleY && frame.maxY <= bottomVisibleY
              showFixedSpecialItem = !isFullyVisible
          }
      }
  }
}

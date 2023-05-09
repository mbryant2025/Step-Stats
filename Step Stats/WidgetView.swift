import SwiftUI

struct WidgetData: Hashable {
    let title: String
    let symbolName: String
    let destination: AnyView
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(symbolName)
    }
        
    static func ==(lhs: WidgetData, rhs: WidgetData) -> Bool {
        return lhs.title == rhs.title && lhs.symbolName == rhs.symbolName
    }
}

struct WidgetView: View {
    let widgets: [WidgetData]
    let buttonHeight: CGFloat
    
    var body: some View {
        generateWidgets()
    }
    
    private func generateWidgets() -> some View {
        ForEach(widgets, id: \.self) { widget in
            NavigationLink(destination: widget.destination) {
                HStack {
                    Text(widget.title)
                        .font(.system(size: 20).bold()) // Make the text bold
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: widget.symbolName)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .frame(height: buttonHeight) // Set a fixed height for the button
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]), // Customize the gradient colors here
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
            .buttonStyle(WidgetButtonStyle())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .transition(.move(edge: .leading))
        }
        .onMove(perform: moveWidget)
    }
    
    private func moveWidget(from source: IndexSet, to destination: Int) {
        withAnimation {
            // Perform the necessary widget movement logic here
        }
    }
}

struct WidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

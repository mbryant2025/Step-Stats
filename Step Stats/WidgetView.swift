import SwiftUI

struct WidgetData: Hashable {
    let title: String // Title of widget
    let destination: AnyView // Where widget goes when tapped
    let symbolName: String // Name of glyph if displayed
    let hasData: Bool // Should display data rather than glyph?
    var data: String // Data point for widget (ex. num steps)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(symbolName)
    }
    
    static func ==(lhs: WidgetData, rhs: WidgetData) -> Bool {
        return lhs.title == rhs.title && lhs.symbolName == rhs.symbolName
    }
}

class WidgetDataStore: ObservableObject {
    @Published var widgets: [WidgetData] = []
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
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: buttonHeight)
                    
                    HStack {
                        Text(widget.title)
                            .font(.system(size: 24).bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if widget.hasData {
                            
                            VStack(alignment: .trailing) {
                                Text(widget.data)
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        } else {
                            
                            Image(systemName: widget.symbolName)
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)

                }
                .cornerRadius(20)
            }
            .buttonStyle(WidgetButtonStyle())
            .padding(.vertical, 5)
            .transition(.move(edge: .leading))
        }
    }
}

struct WidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

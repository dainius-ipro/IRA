
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(radius: 10)
                
                Text("Powered by IPRO")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Innovation. Reliability. Automation.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    ContentView()
}

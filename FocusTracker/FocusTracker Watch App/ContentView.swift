import SwiftUI

struct ContentView: View {
    // 위에서 만든 로직 매니저를 연결합니다.
    @StateObject var healthManager = HealthKitManager()
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.24, green: 0.03, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.16))
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 28))
                        .scaleEffect(healthManager.lastHeartRate > 0 ? 1.08 : 0.94)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: healthManager.lastHeartRate)
                }
                    
                Text("\(Int(healthManager.lastHeartRate))")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("BPM")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(heartRateStatus)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.16))
                    .clipShape(Capsule())
                
                if healthManager.lastHeartRate == 0 {
                    Button("측정 시작") {
                        healthManager.requestAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                }
                
                if let start = healthManager.startTime {
                    VStack(spacing: 3) {
                        Text("SESSION")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                        
                        Text(timeElapsedTime(from: start))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .onReceive(timer) { input in
                        self.now = input
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .padding(8)
        }
    }

    func timeElapsedTime(from date: Date) -> String {
        let diff = Int(now.timeIntervalSince(date))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var heartRateStatus: String {
        switch healthManager.lastHeartRate {
        case 0:
            return "IDLE"
        case ..<60:
            return "CALM"
        case 60..<100:
            return "FOCUS"
        default:
            return "ACTIVE"
        }
    }
    
    private var statusColor: Color {
        switch healthManager.lastHeartRate {
        case 0:
            return .gray
        case ..<60:
            return .mint
        case 60..<100:
            return .orange
        default:
            return .pink
        }
    }
}

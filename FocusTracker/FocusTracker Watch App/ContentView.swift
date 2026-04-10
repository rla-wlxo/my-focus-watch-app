import SwiftUI

struct ContentView: View {
    // 위에서 만든 로직 매니저를 연결합니다.
    @StateObject var healthManager = HealthKitManager()
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 12) {
            // 심박수 아이콘
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.system(size: 30))
            // 심박수가 감지되면 심장이 뛰는 효과
                .scaleEffect(healthManager.lastHeartRate > 0 ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: healthManager.lastHeartRate)
            
            // 실시간 BPM 숫자
            Text("\(Int(healthManager.lastHeartRate))")
                .font(.system(size: 45, weight: .bold))
            
            Text("BPM")
                .font(.caption)
                .foregroundColor(.gray)
            
            // 데이터가 0일 때만 권한 버튼 노출
            if healthManager.lastHeartRate == 0 {
                Button("측정 시작") {
                    healthManager.requestAuthorization()
                }
                .tint(.blue)
                .controlSize(.small)
            }
            
            if let start = healthManager.startTime {
                VStack {
                    Text("측정 시간")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    // 시작 시간과 현재 시간의 차이를 계산하여 표시 (HH:mm:ss 형식)
                    Text(timeElapsedTime(from: start))
                        .font(.system(size: 20, design: .monospaced))
                        .bold()
                }
                .onReceive(timer) { input in
                    self.now = input
                }
            }
        }
    }
    func timeElapsedTime(from date: Date) -> String {
            let diff = Int(now.timeIntervalSince(date))
            let hours = diff / 3600
            let minutes = (diff % 3600) / 60
            let seconds = diff % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
}

import SwiftUI

struct ContentView: View {
    @StateObject var connector = PhoneConnector.shared
    @State private var pairingCode: String = "" // 유저가 입력할 페어링 코드
    @State private var isPaired: Bool = false    // 페어링 성공 여부
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.15), Color(red: 0.15, green: 0.04, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.white, .pink.opacity(0.8))
                    
                    Text("FocusTracker")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(isPaired ? "실시간 심박수를 브라우저와 동기화하고 있습니다." : "브라우저 페어링 코드를 입력하고 세션을 시작하세요.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.72))
                }
                    
                Group {
                    if !isPaired {
                        pairingCard
                    } else {
                        connectedCard
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 24)
        }
    }
    
    private var pairingCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Pairing", systemImage: "link.circle.fill")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            
            Text("웹 브라우저의 6자리 코드를 입력하세요")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
            
            TextField("6자리 코드 입력", text: $pairingCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                )
            
            Button(action: startPairing) {
                HStack {
                    Text("브라우저와 연결")
                    Spacer()
                    Image(systemName: "arrow.up.right.circle.fill")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.pink, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var connectedCard: some View {
        VStack(spacing: 20) {
            HStack {
                Label("Live Session", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                Spacer()
                Text("PAIRED")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 8) {
                Text("\(Int(connector.receivedHeartRate))")
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("BPM")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.68))
            }
            
            HStack(spacing: 12) {
                statusPill(title: "상태", value: heartRateStatus)
                statusPill(title: "코드", value: pairingCode)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func statusPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
            Text(value.isEmpty ? "--" : value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }
    
    private var heartRateStatus: String {
        switch connector.receivedHeartRate {
        case ..<60:
            return "회복"
        case 60..<100:
            return "집중"
        default:
            return "활성"
        }
    }
    
    // 🚀 서버에 페어링 코드를 등록하는 함수
    func startPairing() {
        guard let url = URL(string: "http://127.0.0.1:3000/api/heartrate") else { return }
        let sanitizedCode = pairingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedCode.isEmpty else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 아이폰의 고유 ID(가상)와 웹의 코드를 묶어서 보냅니다.
        let body: [String: Any] = [
            "pairingCode": sanitizedCode,
            "deviceId": "iphone_user_1" // 실제로는 유저 ID 등을 사용
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.isPaired = true
                    self.pairingCode = sanitizedCode
                    // 페어링 성공 시, 이후부터 들어오는 심박수는 이 코드와 매칭되어 서버로 전송됩니다.
                    PhoneConnector.shared.currentPairingCode = sanitizedCode
                }
            }
        }.resume()
    }
}

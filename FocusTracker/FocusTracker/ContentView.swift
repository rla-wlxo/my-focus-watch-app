import SwiftUI

struct ContentView: View {
    @StateObject var connector = PhoneConnector.shared
    @State private var pairingCode: String = "" // 유저가 입력할 페어링 코드
    @State private var isPaired: Bool = false    // 페어링 성공 여부
    
    var body: some View {
        VStack(spacing: 25) {
            Text("FocusTracker")
                .font(.largeTitle).bold()
            
            if !isPaired {
                // 페어링 전 화면
                VStack(spacing: 15) {
                    Text("웹 브라우저의 페어링 코드를 입력하세요")
                        .font(.subheadline)
                    
                    TextField("6자리 코드 입력", text: $pairingCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .frame(width: 200)
                    
                    Button("브라우저와 연결") {
                        startPairing()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // 페어링 후 화면 (기존 심박수 표시)
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 50))
                    Text("브라우저 연결됨")
                    
                    Text("\(Int(connector.receivedHeartRate))")
                        .font(.system(size: 80, weight: .black))
                    Text("BPM")
                }
            }
        }
        .padding()
    }
    
    // 🚀 서버에 페어링 코드를 등록하는 함수
    func startPairing() {
        guard let url = URL(string: "http://127.0.0.1:3000/api/heartrate") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 아이폰의 고유 ID(가상)와 웹의 코드를 묶어서 보냅니다.
        let body: [String: Any] = [
            "pairingCode": pairingCode,
            "deviceId": "iphone_user_1" // 실제로는 유저 ID 등을 사용
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.isPaired = true
                    // 페어링 성공 시, 이후부터 들어오는 심박수는 이 코드와 매칭되어 서버로 전송됩니다.
                    PhoneConnector.shared.currentPairingCode = pairingCode
                }
            }
        }.resume()
    }
}

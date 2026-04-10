import Foundation
import WatchConnectivity

class PhoneConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = PhoneConnector()
    
    @Published var receivedHeartRate: Double = 0
    var currentPairingCode: String? // 현재 연결된 브라우저 코드 저장
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // 1. 워치 -> 아이폰 데이터 전송 함수
    func sendHeartRateToPhone(_ heartRate: Double) {
        if WCSession.default.isReachable {
            let data: [String: Any] = ["heartRate": heartRate]
            WCSession.default.sendMessage(data, replyHandler: nil, errorHandler: { error in
                print("전송 실패: \(error.localizedDescription)")
            })
        }
    }
    
    // 2. 아이폰에서 데이터 수신 및 서버 전송 호출
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let heartRate = message["heartRate"] as? Double {
                self.receivedHeartRate = heartRate
                print("아이폰 수신 완료: \(heartRate)")
                
                // 🚀 Next.js 서버로 전송 시도
                self.sendToServer(heartRate: heartRate)
            }
        }
    }
    
    // 3. Next.js 서버 전송 함수 (아이폰 전용)
    func sendToServer(heartRate: Double) {
        // 페어링이 된 상태에서만 서버로 전송
        guard let pairingCode = currentPairingCode else { return }
        guard let url = URL(string: "http://당신의_IP:3000/api/heartrate") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 심박수와 함께 페어링 코드를 같이 보냅니다.
        let body: [String: Any] = [
            "pairingCode": pairingCode,
            "heartRate": heartRate
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            print("서버 전송 시도 중 (Code: \(pairingCode))")
        }.resume()
    }
    
    // 4. 필수 Delegate 메서드들
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
#endif
}

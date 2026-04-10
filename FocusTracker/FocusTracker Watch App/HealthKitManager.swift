import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private var healthStore = HKHealthStore()
    @Published var lastHeartRate: Double = 0
    @Published var startTime: Date? = nil // 측정 시작 시간 저장
    
    init() {
        requestAuthorization()
        
        // 🚀 [테스트 코드 추가] 2초마다 70~90 사이의 랜덤 숫자를 생성합니다.
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let fakeHR = Double.random(in: 70...90)
            
            DispatchQueue.main.async {
                // 1. 워치 화면의 숫자를 바꿉니다.
                self.lastHeartRate = fakeHR
                
                // 2. 이 숫자를 아이폰으로 전송합니다.
                PhoneConnector.shared.sendHeartRateToPhone(fakeHR)
                
                print("테스트 데이터 발송 중: \(fakeHR)")
            }
        }
    }
    
    func requestAuthorization() {
        // 읽고 싶은 데이터 타입 (심박수) 정의
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set = [heartRateType]
        
        // 시스템 권한 요청
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.startHeartRateQuery()
            }
        }
    }
    
    func startHeartRateQuery() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // 실시간 업데이트를 위한 쿼리 설정
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, newAnchor, error) in
            self.updateHeartRate(samples: samples)
        }
        
        // 데이터가 변할 때마다 호출되는 핸들러
        query.updateHandler = { (query, samples, deletedObjects, newAnchor, error) in
            self.updateHeartRate(samples: samples)
        }
        
        healthStore.execute(query)
    }
    
    
    
    private func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            if let lastSample = heartRateSamples.last {
                let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.lastHeartRate = lastSample.quantity.doubleValue(for: unit)
            }
        }
        
        DispatchQueue.main.async {
            if let lastSample = heartRateSamples.last {
                let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let hrValue = lastSample.quantity.doubleValue(for: unit)
                self.lastHeartRate = hrValue
                PhoneConnector.shared.sendHeartRateToPhone(hrValue)
            }
        }
    }
}

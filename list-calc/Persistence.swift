import Foundation

struct SavedCalculation: Identifiable, Codable {
    var id: UUID
    var title: String
    var memo: String
    var date: Date
    let calculatorState: CalculatorState
}

class PersistenceManager {
    static private let userDefaultsKey = "SavedCalculations"

    static func save(calculations: [SavedCalculation]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(calculations)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("データの保存に失敗しました: \(error.localizedDescription)")
        }
    }

    static func load() -> [SavedCalculation] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let calculations = try decoder.decode([SavedCalculation].self, from: data)
            return calculations.sorted { $0.date > $1.date }
        } catch {
            print("データの読み込みに失敗しました: \(error.localizedDescription)")
            return []
        }
    }
}

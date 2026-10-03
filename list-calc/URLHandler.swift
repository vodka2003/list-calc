import Foundation
import FirebaseFirestore

// MARK: - URLHandler
struct URLHandler {
    
    // 共有URLのIDからFirestore上の計算データを復元する。
    static func handleIncomingURL(url: URL, completion: @escaping (String) -> Void) {
        
        guard url.scheme == "listcalc", url.host == "import" else {
            completion("【エラーA】アプリ専用のURL形式ではありません。")
            return
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            completion("【エラーB】URLの構造を解析できませんでした。")
            return
        }
        
        guard let queryItem = components.queryItems?.first(where: { $0.name == "id" }),
              let documentId = queryItem.value else {
            completion("【エラーC】URLの中にカギ(?id=)が見つかりません。")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("shared_calculations").document(documentId).getDocument { document, error in
            if let error = error {
                completion("データベースからの取得に失敗しました: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let dataText = document.data()?["dataText"] as? String else {
                completion("指定されたデータがサーバーに見つかりませんでした。")
                return
            }
            
            let fixedBase64String = dataText.replacingOccurrences(of: " ", with: "+")
            guard let data = Data(base64Encoded: fixedBase64String) else {
                completion("【エラーE】データの復元に失敗しました。")
                return
            }
            
            do {
                var importedData = try JSONDecoder().decode(SavedCalculation.self, from: data)
                importedData.id = UUID()
                importedData.title = importedData.title + " (共有)"
                importedData.date = Date()
                
                var savedList = PersistenceManager.load()
                savedList.insert(importedData, at: 0)
                PersistenceManager.save(calculations: savedList)
                
                completion("「\(importedData.title)」を保存データ一覧に追加しました！")
                
            } catch {
                completion("【エラーF】データの解読に失敗しました: \(error.localizedDescription)")
            }
        }
    }
}

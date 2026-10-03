import SwiftUI
import FirebaseFirestore
import LinkPresentation

struct SaveLoadView: View {
    @ObservedObject var model: CalculatorModel
    @Binding var isPresented: Bool
    @State private var savedCalculations: [SavedCalculation] = []
    
    @State private var title: String = ""
    @State private var memo: String = ""
    @State private var editingItem: SavedCalculation? = nil
    @State private var shareURL: URL? = nil
    @State private var isShowingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: SavedCalculation? = nil
    @State private var isUploading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // MARK: - 保存
                    Form {
                        Section(header: Text("現在のリストを保存")) {
                            TextField("タイトル", text: $title)
                            TextField("メモ", text: $memo)
                            
                            Button(action: saveCurrentCalculation) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "square.and.arrow.down")
                                    Text("保存")
                                    Spacer()
                                }
                            }
                            .disabled(title.isEmpty)
                        }
                        
                        // MARK: - 読み込み
                        Section(header: Text("保存したデータ")) {
                            if savedCalculations.isEmpty {
                                Text("保存されたデータはありません。")
                                    .foregroundColor(.secondary)
                            } else {
                                List {
                                    ForEach(savedCalculations) { calculation in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(calculation.title)
                                                .font(.headline)
                                            
                                            if !calculation.memo.isEmpty {
                                                Text(calculation.memo)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Text(calculation.date, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Spacer()
                                                Button("読み込む") {
                                                    loadCalculation(calculation)
                                                }
                                                .buttonStyle(.bordered)
                                                Button("共有") {
                                                    uploadAndShare(calculation: calculation)
                                                }
                                                .buttonStyle(.bordered)
                                                Button("編集") {
                                                    editingItem = calculation
                                                }
                                                .buttonStyle(.bordered)
                                                
                                                
                                                Button("削除", role: .destructive) {
                                                    itemToDelete = calculation
                                                    showingDeleteAlert = true
                                                }
                                                .buttonStyle(.bordered)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }}
            .navigationTitle("保存と読み込み")
            .navigationBarItems(trailing: Button("完了") {
                isPresented = false
            })
            .onAppear(perform: loadSavedData)
            .sheet(item: $editingItem) { itemToEdit in
                EditSavedDataView(
                    initialTitle: itemToEdit.title,
                    initialMemo: itemToEdit.memo,
                    onSave: { newTitle, newMemo in
                        updateCalculation(id: itemToEdit.id, newTitle: newTitle, newMemo: newMemo)
                        editingItem = nil
                    },
                    onCancel: {
                        editingItem = nil
                    }
                )
            }
            .alert("本当に削除しますか？", isPresented: $showingDeleteAlert, presenting: itemToDelete) { item in
                Button("キャンセル", role: .cancel) {
                    itemToDelete = nil
                }
                Button("削除", role: .destructive) {
                    deleteCalculation(item)
                    itemToDelete = nil
                }
            } message: { item in
                Text("「\(item.title)」を削除します。この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Local Storage

    private func loadSavedData() {
        savedCalculations = PersistenceManager.load()
    }
    
    private func saveCurrentCalculation() {
        let currentState = model.getCurrentState()
        
        let newSave = SavedCalculation(
            id: UUID(),
            title: title,
            memo: memo,
            date: Date(),
            calculatorState: currentState
        )
        
        savedCalculations.insert(newSave, at: 0)
        
        PersistenceManager.save(calculations: savedCalculations)
        
        title = ""
        memo = ""
    }
    
    private func loadCalculation(_ calculation: SavedCalculation) {
        model.loadState(calculation.calculatorState)
        isPresented = false
    }
    
    private func deleteCalculation(_ calculation: SavedCalculation) {
        savedCalculations.removeAll { $0.id == calculation.id }
        PersistenceManager.save(calculations: savedCalculations)
    }
    
    private func updateCalculation(id: UUID, newTitle: String, newMemo: String) {
        guard let index = savedCalculations.firstIndex(where: { $0.id == id }) else {
            print("Error: 更新対象のデータが見つかりません。")
            return
        }
        
        savedCalculations[index].title = newTitle
        savedCalculations[index].memo = newMemo
        
        PersistenceManager.save(calculations: savedCalculations)
    }
    private func generateShareFile(for calculation: SavedCalculation) -> URL? {
        do {
            let data = try JSONEncoder().encode(calculation)
            
            let safeTitle = calculation.title.isEmpty ? "計算データ" : calculation.title
            let fileName = "\(safeTitle).listcalc"
            
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            
            return fileURL
            
        } catch {
            print("共有ファイルの作成に失敗しました: \(error)")
            return nil
        }
    }
    // MARK: - Sharing
    private func generateShareURLText(for calculation: SavedCalculation) -> String? {
        do {
            let data = try JSONEncoder().encode(calculation)
            let base64String = data.base64EncodedString()
            guard let encodedString = base64String.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            let urlString = "https://list-calc-app-sota.blogspot.com/p/listcalc.html?data=\(encodedString)"
            
            return urlString
            
        } catch {
            print("URL生成失敗: \(error)")
            return nil
        }
    }
    private func uploadAndShare(calculation: SavedCalculation) {
        isUploading = true
        
        let db = Firestore.firestore()
        let newDocRef = db.collection("shared_calculations").document()
        let shortID = newDocRef.documentID
        
        do {
            let data = try JSONEncoder().encode(calculation)
            let base64String = data.base64EncodedString()
            
            newDocRef.setData(["dataText": base64String]) { error in
                
                // FirestoreのコールバックからUI状態を更新するためメインキューへ戻す。
                DispatchQueue.main.async {
                    self.isUploading = false
                    
                    if let error = error {
                        print("アップロード失敗: \(error.localizedDescription)")
                        return
                    }
                    
                    let shortURLString = "https://list-calc-app-sota.blogspot.com/p/listcalc.html?id=\(shortID)"
                    
                    if let url = URL(string: shortURLString) {
                        
                        let shareTitle = calculation.title.isEmpty ? "計算データ" : calculation.title
                        self.presentShareSheet(url: url, title: shareTitle)
                    }
                }
            }
        } catch {
            print("データ変換エラー: \(error)")
            DispatchQueue.main.async {
                self.isUploading = false
            }
        }
    }
    // MARK: - Share Sheet
    private func presentShareSheet(url: URL, title: String) {
        
        let itemSource = ShareItemSource(url: url, title: title)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // 現在表示中のViewControllerから共有シートを提示する。
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootVC = window.rootViewController {
            
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            // iPadでは表示元を指定しないとクラッシュするため、画面中央を起点にする。
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Share Item Source
class ShareItemSource: NSObject, UIActivityItemSource {
    let shareURL: URL
    let title: String
    
    init(url: URL, title: String) {
        self.shareURL = url
        self.title = title
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return shareURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        
        // LINEではURL単体の共有が失敗する場合があるため、テキストとして渡す。
        if let type = activityType?.rawValue, type.lowercased().contains("line") {
            return "共有データが届いています！\n\(title)\n\(shareURL.absoluteString)"
        }
        
        return shareURL
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = shareURL
        metadata.url = shareURL
        metadata.title = title
        return metadata
    }
}

import SwiftUI

// MARK: - MemoEditView
struct MemoEditView: View {
    @ObservedObject var model: CalculatorModel
    let listIndex: Int
    let lineIndex: Int
    var onDismiss: () -> Void
    
    @State private var memo: String
    @FocusState private var isMemoFieldFocused: Bool
    
    init(model: CalculatorModel, listIndex: Int, lineIndex: Int, initialMemo: String, onDismiss: @escaping () -> Void) {
        self.model = model
        self.listIndex = listIndex
        self.lineIndex = lineIndex
        self._memo = State(initialValue: initialMemo)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("メモ")) {
                    TextField("入力欄", text: $memo)
                        .focused($isMemoFieldFocused)
                }
            }
            .navigationTitle("メモを編集")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    isMemoFieldFocused = false
                    onDismiss()
                },
                trailing: Button("保存") {
                    isMemoFieldFocused = false
                    model.setMemo(listIndex: listIndex, lineIndex: lineIndex, memo: memo)
                    onDismiss()
                }
            )
            .onAppear {
                // シート表示アニメーション完了後に入力欄へフォーカスする。
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isMemoFieldFocused = true
                }
            }
        }
    }
}

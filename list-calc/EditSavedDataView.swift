import SwiftUI

struct EditSavedDataView: View {
    @State private var title: String
    @State private var memo: String
    
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    
    init(initialTitle: String, initialMemo: String,
         onSave: @escaping (String, String) -> Void,
         onCancel: @escaping () -> Void) {
        
        self._title = State(initialValue: initialTitle)
        self._memo = State(initialValue: initialMemo)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("保存データを編集")) {
                    TextField("タイトル", text: $title)
                    TextField("メモ", text: $memo)
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    onCancel()
                },
                trailing: Button("保存") {
                    onSave(title, memo)
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

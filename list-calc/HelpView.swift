import SwiftUI

struct HelpView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HelpSection(title: "⚫︎メモ機能", content: "キーパッドの「Memo」ボタンを押すと、現在選択している行にメモを追加・編集できます。")

                    HelpSection(title: "⚫︎リストの操作", content:
                        "キーパッド2行目の「＋」「ゴミ箱」ボタンで、計算リストを2〜4個の間で増やしたり減らしたりできます。")

                    HelpSection(title: "⚫︎行の操作", content: "・行をタップ: その行を選択します。\n・行を長押し: 行を一つ下にずらし、空の行を挿入します。\n・行を左にスワイプ: その行を削除します。")

                    HelpSection(title: "⚫︎ショートカット", content: "設定画面で数式を登録し、対応するボタンを長押しすると式が挿入されます。")
                    
                    HelpSection(title: "⚫︎リスト間のコピー", content: "リスト選択ボタンをドラッグ&ドロップすることで内容をコピペすることができます。また、iPadの場合は各リストの下にある「Copy」ボタンでリスト全体をコピーし、別のリストの「Paste」ボタンで内容をコピペできます。")
                    
                    HelpSection(title: "⚫︎保存と読み込み", content: "画面左上の「保存」アイコンを押すと、現在の計算リスト全体（メモ含む）に名前を付けて保存できます。保存したデータは、同じ画面から「読み込む」または「削除」できます。")
                    
                    HelpSection(title: "⚫︎表示モード (iPad横画面のみ)", content: "iPadを横向きにしている時に表示される「人の上半身」のアイコンボタンです。\nタップすると、キーパッドや操作ボタン（AC, Copyなど）が非表示になり、計算リストが画面いっぱいに拡大されます。")
                
                    HelpSection(title: "⚫︎設定", content: "設定画面では、起動時のリスト数やメモ・AC ALLボタンの表示／非表示の切り替え、色彩設定、キーパッドの左右反転ができます。")
                    
                    Spacer()

                }
                .padding()
            }
            .navigationTitle("アプリの使い方")
            .navigationBarItems(trailing: Button("閉じる") {
                isPresented = false
            })
        }
    }
}

struct HelpSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            Text(content)
                .font(.body)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

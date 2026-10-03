import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    let helpURL = URL(string: "https://list-calc-app-sota.blogspot.com/2026/02/blog-post.html")!
    @ObservedObject var model: CalculatorModel
    @EnvironmentObject var adManager: AppAdManager
    @Binding var isPresented: Bool

    @State private var defaultListCount: Int = 2
    @State private var showMemoButton: Bool = true
    @State private var isShowingHelpView = false
    @State private var showAcAllButton: Bool = true
    @State private var selectedTheme: AppThemeColor = .defaultBlue
    @State private var selectedLayout: LayoutDirection = .rightHanded
    @State private var showHelpWeb = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("広告を非表示")) {
                    Button(action: { adManager.showRewardedAd() }) {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("動画を見て広告を12時間非表示にする")
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .disabled(adManager.isRewardedAdLoading || !adManager.isRewardedAdReady)
                    if adManager.isRewardedAdLoading {
                        Text("広告を読み込み中…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !adManager.isRewardedAdReady && !adManager.isRewardedAdLoading {
                        Text("広告の準備ができていません。しばらくしてから再度お試しください。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        if !adManager.shouldShowBanner, let remainingText = adManager.getRemainingTimeText() {
                                Text("現在広告は非表示です (\(remainingText))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .fontWeight(.bold)
                            } else {
                                Text("動画を最後まで視聴すると、バナーが12時間表示されなくなります。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                    }
                }

                Section(header: Text("長押しショートカット")) {
                    
                    let shortcutKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "00", "."]

                    DisclosureGroup(
                        content: {
                            ForEach(shortcutKeys, id: \.self) { key in
                                NavigationLink(destination: FormulaEditView(model: model, key: key)) {
                                    HStack {
                                        Text("ボタン [ \(key) ]")
                                            .font(.body)
                                        Spacer()
                                        
                                        if let formula = model.savedFormulas[key] {
                                            Text("\(formula.operation) \(formula.value)")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                            if let memo = formula.memo, !memo.isEmpty {
                                                                    Text(memo)
                                                                        .foregroundColor(.gray)
                                                                        .font(.caption)
                                                                }
                                        } else {
                                            Text("未設定")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text("ショートカット登録")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(model.savedFormulas.count)個 設定中")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    )
                }
                
                Section(header: Text("起動時設定")) {
                    Stepper(value: $defaultListCount, in: 2...4) {
                        Text("起動時のリスト数: \(defaultListCount)")
                    }
                    Text("設定は次回のアプリ起動時から反映されます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("キーパッド設定")) {
                    Toggle("メモボタンを表示する", isOn: $showMemoButton)
                        .onChange(of: showMemoButton) {
                            model.setShowMemoButton(isOn: showMemoButton)
                        }
                    
                    Toggle("AC All ボタンを表示する", isOn: $showAcAllButton)
                        .onChange(of: showAcAllButton) {
                            model.setShowAcAllButton(isOn: showAcAllButton)
                        }
                    
                    Text("設定はすぐに反映されます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section(header: Text("キーパッド配置")) {
                    Picker("利き手", selection: $selectedLayout) {
                        ForEach(LayoutDirection.allCases) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedLayout) {
                        model.setLayoutDirection(selectedLayout)
                    }

                    Text("キーパッドの位置を反転します。\n設定はすぐに反映されます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("色彩設定")) {
                    let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 15), count: 5)
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(AppThemeColor.allCases) { theme in
                            VStack {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 45, height: 45) 
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.headline.weight(.bold))
                                            .foregroundColor(.white)
                                            .opacity(selectedTheme == theme ? 1.0 : 0.0)
                                    )
                                    .onTapGesture {
                                        selectedTheme = theme
                                    }
                                
                                Text(theme.displayName)
                                    .font(.caption)
                                    .foregroundColor(selectedTheme == theme ? .primary : .secondary)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    
                    .onChange(of: selectedTheme) {
                        model.setAppThemeColor(color: selectedTheme)
                    }

                    Text("設定はすぐに反映されます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("サポート")) {
                                    Button(action: { showHelpWeb = true }) {
                                        Label("アプリの使い方 (ヘルプ)", systemImage: "questionmark.circle")
                                            .foregroundColor(.primary)
                                    }
                                }
            }
            .navigationTitle("設定")
            .navigationBarItems(trailing: Button("完了") {
                model.setDefaultListCount(count: defaultListCount)
                isPresented = false
            })
            .onAppear {
                defaultListCount = model.getDefaultListCount()
                showMemoButton = model.getShowMemoButton()
                showAcAllButton = model.getShowAcAllButton()
                selectedTheme = model.getAppThemeColor()
                selectedLayout = model.getLayoutDirection()
                adManager.loadRewardedAd()
            }
        }
        .sheet(isPresented: $showHelpWeb) {
                    SafariView(url: helpURL)
                        .edgesIgnoringSafeArea(.all)
                }
    }
    
}

struct FormulaEditView: View {
    @ObservedObject var model: CalculatorModel
    let key: String
    
    let operators = ["+", "-", "×", "÷"]
    
    @State private var selectedOp = "+"
    @State private var inputValue = ""
    @State private var inputMemo = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("式の設定")) {
                Picker("演算子", selection: $selectedOp) {
                    ForEach(operators, id: \.self) { op in
                        Text(op).tag(op)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                TextField("数値 (最大15桁)", text: $inputValue)
                    .keyboardType(.decimalPad)
                    .onChange(of: inputValue) { newValue in
                        // 数字とドット以外を除去 & 15桁制限
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered.count > 15 {
                            inputValue = String(filtered.prefix(15))
                        } else {
                            inputValue = filtered
                        }
                    }
                TextField("メモ (例: 消費税8%)", text: $inputMemo)
            }
            
            Section {
                Button("保存する") {
                    if !inputValue.isEmpty {
                        let memoToSave = inputMemo.isEmpty ? nil : inputMemo
                        model.saveFormula(key: key, operation: selectedOp, value: inputValue, memo: memoToSave)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(inputValue.isEmpty)
                
                Button("設定を削除", role: .destructive) {
                    model.savedFormulas.removeValue(forKey: key)
                    // 削除後のショートカット設定を永続化する。
                    if let encoded = try? JSONEncoder().encode(model.savedFormulas) {
                        UserDefaults.standard.set(encoded, forKey: "savedFormulas")
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("ボタン [ \(key) ] の設定")
        .onAppear {
            if let formula = model.savedFormulas[key] {
                selectedOp = formula.operation
                inputValue = formula.value
                inputMemo = formula.memo ?? ""
            }
        }
    }
}

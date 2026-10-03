import SwiftUI
import FirebaseFirestore

// MARK: - ContentView
struct ContentView: View {
    @State private var isShowingSaveLoadView = false
    @State private var isShowingSettingsView = false
    @StateObject var model = CalculatorModel()
    @State private var isPresentationMode: Bool = false
    @State private var adHeight: CGFloat = 50
    @State private var showImportAlert = false
    @State private var importMessage = ""
    @EnvironmentObject var adManager: AppAdManager
    @Environment(\.scenePhase) private var scenePhase
    
    private let acButtonHeight: CGFloat = 45
    private let acButtonPadding: CGFloat = 16
    private let acButtonWidth: CGFloat = 120
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            
            model.appThemeColor.color
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    VStack(spacing: 0) {
                        if adManager.shouldShowBanner {
                            GeometryReader { adGeometry in
                                AdBannerView(
                                    width: adGeometry.size.width,
                                    adHeight: $adHeight
                                )
                            }
                            .frame(height: adHeight)
                            .background(Color.black.opacity(0.1))
                        }
                        
                        topDisplayArea(geometry: geometry, isLandscape: isLandscape, isPad: isPad)
                        
                        bottomArea(geometry: geometry, isLandscape: isLandscape, isPad: isPad)
                    }
                )
        }
        .alert("すべてのリストを消去", isPresented: $model.showAcAllConfirmation) {
            Button("消去する", role: .destructive) {
                model.clearAllLists()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("全てのリストを消去しますか？")
        }
        .sheet(item: $model.memoItemToEdit) { item in
            MemoEditView(
                model: model,
                listIndex: item.listIndex,
                lineIndex: item.lineIndex,
                initialMemo: item.memo,
                onDismiss: {
                    model.memoItemToEdit = nil
                }
            )
        }
        .sheet(isPresented: $isShowingSaveLoadView) {
            SaveLoadView(model: model, isPresented: $isShowingSaveLoadView)
        }
        .sheet(isPresented: $isShowingSettingsView) {
            SettingsView(model: model,isPresented: $isShowingSettingsView)
                .environmentObject(adManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .inactive || newPhase == .background {
                model.saveAutoResumeData()
            }
        }
        .onOpenURL { url in
            
            URLHandler.handleIncomingURL(url: url) { message in
                
                DispatchQueue.main.async {
                    importMessage = message
                    showImportAlert = true
                }
            }
        }
        .alert("データ受信", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
    }
    
    private func resultDisplayView(for total: String, listCount: Int) -> some View {
        let fontSize: CGFloat = (listCount == 4) ? 50 : 70
        
        return VStack(spacing: 0) {
            Spacer()
            HStack {
                Spacer()
                Text(total)
                    .font(.system(size: fontSize, weight: .light))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    private func acButtonView(for listIndex: Int) -> some View {
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        return HStack(spacing: 4) {
            Button(action: { model.clearList(at: listIndex) }) {
                Text("AC")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .frame(height: acButtonHeight)
                    .background(Color(.systemGray3))
                    .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.25))
                    .cornerRadius(5)
            }
            
            if !isPhone {
                Button(action: { model.copyList(at: listIndex) }) {
                    Text("コピー")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .frame(height: acButtonHeight)
                        .background(Color(.systemGray3))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.25))
                        .cornerRadius(5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.2)
                }
                
                Button(action: { model.pasteList(at: listIndex) }) {
                    Text("ペースト")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .frame(height: acButtonHeight)
                        .background(Color(.systemGray3))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.25))
                        .cornerRadius(5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.2)
                }
            }
        }
        .padding(.horizontal, acButtonPadding)
        .padding(.top, 2)
        .padding(.bottom, acButtonPadding / 2)
        .frame(height: acButtonHeight + acButtonPadding)
    }
    
    @ViewBuilder
    private func topDisplayArea(geometry: GeometryProxy, isLandscape: Bool, isPad: Bool) -> some View {
        HStack(spacing: 0) {
            if !isLandscape{
                HStack(spacing: 8) {
                    Button(action: { isShowingSaveLoadView = true }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { isShowingSettingsView = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                                            withAnimation { model.toggleMobileMode() }
                                        }) {
                                            Image(systemName: "square.split.1x2")
                                                .font(.system(size: 35))
                                                .foregroundColor(.white)
                                                .frame(width: 45, height: 45)
                                                .background(Color.white.opacity(model.isMobileMode ? 0.3 : 0.0))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                }
                .padding(.leading)
                Spacer()
            }
            
            HStack(spacing: 0) {
                if isLandscape && isPad {
                    let controlWidth: CGFloat = isPresentationMode ? 120 : (geometry.size.width / 3)
                    let displayWidth: CGFloat = geometry.size.width - controlWidth
                    let colCount = model.isMobileMode ? (model.lists.count / 2) : model.lists.count
                    
                    if model.layoutDirection == .leftHanded {
                        HStack(spacing: 20) {
                            Spacer()
                            if !isPresentationMode {
                                Button(action: { isShowingSaveLoadView = true }) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 80)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                
                                Button(action: { isShowingSettingsView = true }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 80)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                Button(action: {
                                    withAnimation { model.toggleMobileMode() }
                                }) {
                                    Image(systemName: "square.split.1x2")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 80)
                                        .background(Color.white.opacity(model.isMobileMode ? 0.6 : 0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            
                            Button(action: { isPresentationMode.toggle() }) {
                                Image(systemName: isPresentationMode ? "person.crop.rectangle.fill" : "person.crop.rectangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(Color.white.opacity(isPresentationMode ? 0.4 : 0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            Spacer()
                        }
                        .frame(width: controlWidth)
                        .animation(.default, value: isPresentationMode)
                        
                        HStack(alignment: .top, spacing: 1) {
                            ForEach(0..<colCount, id: \.self) { index in
                                if model.listTotals.indices.contains(index) {
                                    resultDisplayView(
                                        for: (model.selectedListIndex == index && !model.currentInputIsNew)
                                        ? model.mainDisplayValue
                                        : model.listTotals[index],
                                        listCount: colCount
                                    )
                                    if index < colCount - 1 {
                                        Divider().background(Color.white)
                                    }
                                }
                            }
                        }.frame(width: displayWidth)
                        
                    } else {
                        HStack(alignment: .top, spacing: 1) {
                            ForEach(0..<colCount, id: \.self) { index in
                                if model.listTotals.indices.contains(index) {
                                    resultDisplayView(
                                        for: (model.selectedListIndex == index && !model.currentInputIsNew)
                                        ? model.mainDisplayValue
                                        : model.listTotals[index],
                                        listCount: colCount
                                    )
                                    if index < colCount - 1 {
                                        Divider().background(Color.white)
                                    }
                                }
                            }
                        }
                        .frame(width: displayWidth)
                        
                        HStack(spacing: 20) {
                            Spacer()
                            if !isPresentationMode {
                                Button(action: { isShowingSaveLoadView = true }) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 80)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                
                                Button(action: { isShowingSettingsView = true }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 80)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                Button(action: {
                                                                    withAnimation { model.toggleMobileMode() }
                                                                }) {
                                                                    Image(systemName: "square.split.1x2")
                                                                        .font(.system(size: 40))
                                                                        .foregroundColor(.white)
                                                                        .frame(width: 80, height: 80)
                                                                        .background(Color.white.opacity(model.isMobileMode ? 0.6 : 0.2))
                                                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                                                }
                            }
                            
                            Button(action: { isPresentationMode.toggle() }) {
                                Image(systemName: isPresentationMode ? "person.crop.rectangle.fill" : "person.crop.rectangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(Color.white.opacity(isPresentationMode ? 0.4 : 0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            Spacer()
                        }
                        .frame(width: controlWidth)
                        .animation(.default, value: isPresentationMode)
                    }
                } else {
                    HStack {
                        Spacer()
                        
                        let colCount = model.isMobileMode ? max(1, model.lists.count / 2) : max(1, model.lists.count)
                        let topIndex = model.selectedListIndex % colCount
                        
                        // 下段編集中は上段の合計を維持し、上段編集中のみ入力値を表示する。
                        let topValue = (model.selectedListIndex == topIndex && !model.currentInputIsNew)
                            ? model.mainDisplayValue
                            : (model.listTotals.indices.contains(topIndex) ? model.listTotals[topIndex] : "0")
                        
                        Text(topValue)
                            .font(.system(size: 70, weight: .light))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.2)
                            .padding(.horizontal)
                    }
                }
            }
        
            .frame(height: 110)
            .animation(Animation.default, value: isPresentationMode)
            .animation(Animation.default, value: model.layoutDirection)
        }
        .background(Color.black.opacity(0.6))
    }
    
    @ViewBuilder
    private func bottomArea(geometry: GeometryProxy, isLandscape: Bool, isPad: Bool) -> some View {
        Group {
            if isLandscape && isPad {
                HStack(alignment: .top, spacing: 1) {
                    let controlWidth: CGFloat = isPresentationMode ? 120 : (geometry.size.width / 3)
                    let displayWidth: CGFloat = geometry.size.width - controlWidth
                    let colCount = model.isMobileMode ? (model.lists.count / 2) : model.lists.count
                    let singleListWidth = displayWidth / CGFloat(colCount)
                    
                    if model.layoutDirection == .leftHanded {
                        if !isPresentationMode {
                            KeypadView(model: model)
                                .frame(width: controlWidth)
                                .transition(.move(edge: .leading))
                        } else {
                            model.appThemeColor.color
                                .frame(width: controlWidth)
                        }
                        HStack(alignment: .top, spacing: 1) {
                            ForEach(0..<colCount, id: \.self) { index in
                                if model.isMobileMode {
                                    MobileColumnView(model: model, columnIndex: index)
                                        .frame(width: singleListWidth)
                                } else {
                                    VStack(spacing: 0) {
                                        SingleHistoryView(model: model, listIndex: index)
                                        if !isPresentationMode {
                                            acButtonView(for: index)
                                        }
                                    }
                                    .frame(width: singleListWidth)
                                }
                            }
                        }
                        .frame(width: displayWidth)
                        
                    } else {
                        HStack(alignment: .top, spacing: 1) {
                                                    ForEach(0..<colCount, id: \.self) { index in
                                                        if model.isMobileMode {
                                                            MobileColumnView(model: model, columnIndex: index)
                                                                .frame(width: singleListWidth)
                                                        } else {
                                                            VStack(spacing: 0) {
                                                                SingleHistoryView(model: model, listIndex: index)
                                                                if !isPresentationMode {
                                                                    acButtonView(for: index)
                                                                }
                                                            }
                                                            .frame(width: singleListWidth)
                                                        }
                                                    }
                                                }
                        .frame(width: displayWidth)
                        if !isPresentationMode {
                            KeypadView(model: model)
                                .frame(width: controlWidth)
                                .transition(.move(edge: .trailing))
                        } else {
                            model.appThemeColor.color
                                .frame(width: controlWidth)
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 1) {
                    let keypadRatio: CGFloat = isPad ? 0.5 : 0.6
                    let listRatio: CGFloat = 1.0 - keypadRatio
                    let totalWidth = geometry.size.width
                    let keypadWidth = totalWidth * keypadRatio
                    let listWidth = totalWidth * listRatio
                    
                    let colCount = model.isMobileMode ? max(1, model.lists.count / 2) : max(1, model.lists.count)
                    let safeColumnIndex = model.selectedListIndex % colCount
                    
                    if model.layoutDirection == .leftHanded {
                        KeypadView(model: model)
                            .frame(width: keypadWidth)
                        
                        VStack(spacing: 0) {
                            if model.isMobileMode {
                                MobileColumnView(model: model, columnIndex: safeColumnIndex)
                            } else {
                                SingleHistoryView(model: model, listIndex: model.selectedListIndex)
                                acButtonView(for: model.selectedListIndex)
                            }
                        }
                        .frame(width: listWidth)
                        
                    } else {
                        VStack(spacing: 0) {
                            if model.isMobileMode {
                                MobileColumnView(model: model, columnIndex: safeColumnIndex)
                            } else {
                                SingleHistoryView(model: model, listIndex: model.selectedListIndex)
                                acButtonView(for: model.selectedListIndex)
                            }
                        }
                        .frame(width: listWidth)
                        
                        KeypadView(model: model)
                            .frame(width: keypadWidth)
                    }
                }
            }
        }
        .animation(Animation.default, value: isPresentationMode)
        .animation(Animation.default, value: model.layoutDirection)
    }
    
    
}

// MARK: - MobileColumnView (携帯モード専用の1列)
struct MobileColumnView: View {
    @ObservedObject var model: CalculatorModel
    let columnIndex: Int
    
    var body: some View {
        let colCount = model.lists.count / 2
        let topIndex = columnIndex
        let bottomIndex = columnIndex + colCount
        
        let bottomTotal = model.listTotals.indices.contains(bottomIndex)
            ? ((model.selectedListIndex == bottomIndex && !model.currentInputIsNew) ? model.mainDisplayValue : model.listTotals[bottomIndex])
            : "0"
        
        return VStack(spacing: 0) {
            
            SingleHistoryView(model: model, listIndex: topIndex)
            
            HStack {
                Spacer()
                Text(bottomTotal)
                    .font(.system(size: 45, weight: .regular))
                    .foregroundColor(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
                    .padding(.horizontal)
            }
            .frame(height: 70)
            .background(Color.black.opacity(0.5))
            
            SingleHistoryView(model: model, listIndex: bottomIndex)
            
            HStack(spacing: 4) {
                Button(action: {
                    model.clearList(at: topIndex)
                }) {
                    Text("上クリア")
                        .font(.subheadline).fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Color(.systemGray3))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.25))
                        .cornerRadius(5)
                }
                
                Button(action: {
                    model.clearList(at: bottomIndex)
                }) {
                    Text("下クリア")
                        .font(.subheadline).fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Color(.systemGray3))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.25))
                        .cornerRadius(5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 5)
            .padding(.bottom, 8)
        }
    }
}
// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPad Pro (11-inch) (4th generation)")
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("iPad Landscape")
            
            ContentView()
                .previewDevice("iPad Pro (11-inch) (4th generation)")
                .previewInterfaceOrientation(.portrait)
                .previewDisplayName("iPad Portrait")
        }
    }
}

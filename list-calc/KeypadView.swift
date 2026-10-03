import SwiftUI

struct KeyButton: View {
    let labelView: AnyView
    let color: Color
    let textColor: Color
    var action: () -> Void
    var buttonWidth: CGFloat
    var buttonHeight: CGFloat
    
    var longPressAction: (() -> Void)? = nil
    
    @State private var isPressed = false
    @State private var longPressTriggered = false
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(isPressed ? color.opacity(0.7) : color)
                .frame(width: buttonWidth, height: buttonHeight)
            
            labelView
                .fontWeight(.regular)
                .foregroundColor(textColor)
        }
        // タップと長押しを排他的に扱うため、タッチ開始・終了を直接検知する。
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if longPressTriggered { return }

                    if !isPressed {
                        isPressed = true
                        
                        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            if let longAction = longPressAction {
                                longAction()
                                longPressTriggered = true
                            }
                            
                            isPressed = false
                        }
                    }
                }
                .onEnded { _ in
                    timer?.invalidate()
                    timer = nil
                    
                    isPressed = false
                    
                    if !longPressTriggered {
                        action()
                    }
                    
                    longPressTriggered = false
                }
        )
    }
}
struct KeypadView: View {
    @ObservedObject var model: CalculatorModel
    
    private let keypadPadding: CGFloat = 8.0
    
    private func buttonColor(label: String) -> Color {
        switch label {
        case "memo","allClear", "C", "ToggleSign", "arrow.uturn.backward", "arrow.uturn.forward","addList", "removeList", "backspace","×", "+", "÷", "-", "=":
            return Color(red: 0.35, green: 0.45, blue: 0.55)
        default:
            return Color(.systemGray4)
        }
    }
    
    private func buttonTextColor(label: String) -> Color {
        switch label {
        case "memo","allClear", "C", "ToggleSign", "arrow.uturn.backward", "arrow.uturn.forward","×", "+", "÷", "-", "=","addList", "removeList", "backspace":
            return .white
        default:
            return Color(red: 0.1, green: 0.15, blue: 0.25)
        }
    }
    
    private func buttonAction(label: String) {
        if label.range(of: "^[0-9\\.]$|00|=+", options: .regularExpression) != nil {
            model.didPressNumber(label)
        } else if label.range(of: "[÷×\\-+\\*/]", options: .regularExpression) != nil {
            model.didPressOperator(label)
        } else if label == "C" {
            model.clearInput()
        } else if label == "AC" {
            model.clearAll()
        } else {
            model.didPressSpecialKey(label)
        }
    }

    private func makeNumberButton(label: String, width: CGFloat, height: CGFloat) -> some View {
            KeyButton(
                labelView: makeTextLabel(label, buttonWidth: width, buttonHeight: height),
                color: buttonColor(label: label),
                textColor: buttonTextColor(label: label),
                action: { buttonAction(label: label) },
                buttonWidth: width,
                buttonHeight: height,
                longPressAction: {
                    if model.savedFormulas[label] != nil {
                        model.executeShortcut(key: label)
                    } else {
                    }
                }
            )
        }

    private func makeTextLabel(_ label: String, buttonWidth: CGFloat, buttonHeight: CGFloat) -> AnyView {
            // 幅と高さの小さい方を基準にラベルサイズを調整する。
            let baseSize = min(buttonWidth, buttonHeight)
            return AnyView(Text(label).font(.system(size: baseSize * 0.7)))
        }
        
        private func makeSymbolLabel(_ systemName: String, buttonWidth: CGFloat, buttonHeight: CGFloat) -> AnyView {
            // 幅と高さの小さい方を基準にラベルサイズを調整する。
            let baseSize = min(buttonWidth, buttonHeight)
            return AnyView(Image(systemName: systemName).font(.system(size: baseSize * 0.7)))
        }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                let numRows: CGFloat = 9.0
                let totalVerticalSpacing = (numRows - 1) * 4.0
                let totalVerticalPadding = keypadPadding * 2
                let finalButtonHeight = (geometry.size.height - totalVerticalSpacing - totalVerticalPadding) / numRows

                let numColsFour: CGFloat = 4.0
                let horizontalSpacingFour = (numColsFour - 1) * 4.0
                let buttonWidthFour = (geometry.size.width - horizontalSpacingFour - keypadPadding * 2) / numColsFour
                
                let numColsThree: CGFloat = 3.0
                let horizontalSpacingThree = (numColsThree - 1) * 4.0
                let buttonWidthThree = (geometry.size.width - horizontalSpacingThree - keypadPadding * 2) / numColsThree
                
                let numColsTwo: CGFloat = 2.0
                let horizontalSpacingTwo = (numColsTwo - 1) * 4.0
                let buttonWidthTwo = (geometry.size.width - horizontalSpacingTwo - keypadPadding * 2) / numColsTwo
                       
                HStack(spacing: 4) {
                                    let colCount = model.isMobileMode ? (model.lists.count / 2) : model.lists.count
                                    
                                    ForEach(0..<colCount, id: \.self) { index in
                                        Button(action: { model.selectList(index: index) }) {
                                            Text("List\(index + 1)")
                                                .font(.system(size: buttonWidthThree * 0.3))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: finalButtonHeight)
                                                .background(model.selectedListIndex == index ? Color.yellow : Color.gray.opacity(0.5))
                                                .foregroundColor(.white)
                                                .cornerRadius(5)
                                        }
                        
                        .onDrag {
                            return NSItemProvider(object: String(index) as NSString)
                        }
                        
                        .onDrop(of: [.plainText], isTargeted: nil) { providers, _ in
                            guard let provider = providers.first else { return false }
                            
                            // NSItemProviderの読み込み完了後、モデル更新をメインキューへ戻す。
                            provider.loadObject(ofClass: NSString.self) { string, error in
                                if let sourceIndexString = string as? String,
                                   let sourceIndex = Int(sourceIndexString) {
                                    
                                    DispatchQueue.main.async {
                                        model.copyList(from: sourceIndex, to: index)
                                    }
                                }
                            }
                            return true
                        }
                    }
                }

                switch (model.showMemoButton, model.showAcAllButton) {

                        case (true, true):
                            HStack(spacing: 4) {
                                KeyButton(labelView: AnyView(Text("メモ").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.7)).lineLimit(1)
                                    .minimumScaleFactor(0.2)), color: buttonColor(label: "memo"), textColor: buttonTextColor(label: "memo"), action: { model.didPressSpecialKey("memo") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Text("AC All").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.7)).lineLimit(1)
                                    .minimumScaleFactor(0.2)), color: buttonColor(label: "allClear"), textColor: buttonTextColor(label: "allClear"), action: { model.didPressSpecialKey("allClear") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Image(systemName: "plus.rectangle.on.rectangle").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "addList"), textColor: buttonTextColor(label: "addList"), action: { model.didPressSpecialKey("addList") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Image(systemName: "trash").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "removeList"), textColor: buttonTextColor(label: "removeList"), action: { model.didPressSpecialKey("removeList") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                            }

                        case (true, false):
                            HStack(spacing: 4) {
                                KeyButton(labelView: AnyView(Text("Memo").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.7)).lineLimit(1)
                                    .minimumScaleFactor(0.2)), color: buttonColor(label: "memo"), textColor: buttonTextColor(label: "memo"), action: { model.didPressSpecialKey("memo") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Image(systemName: "plus.rectangle.on.rectangle").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "addList"), textColor: buttonTextColor(label: "addList"), action: { model.didPressSpecialKey("addList") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Image(systemName: "trash").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "removeList"), textColor: buttonTextColor(label: "removeList"), action: { model.didPressSpecialKey("removeList") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                            }

                        case (false, true):
                            HStack(spacing: 4) {
                                KeyButton(labelView: AnyView(Text("AC All").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.7)).lineLimit(1)
                                    .minimumScaleFactor(0.2)), color: buttonColor(label: "allClear"), textColor: buttonTextColor(label: "allClear"), action: { model.didPressSpecialKey("allClear") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Image(systemName: "plus.rectangle.on.rectangle").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "addList"), textColor: buttonTextColor(label: "addList"), action: { model.didPressSpecialKey("addList") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Image(systemName: "trash").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "removeList"), textColor: buttonTextColor(label: "removeList"), action: { model.didPressSpecialKey("removeList") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                            }

                        case (false, false):
                            HStack(spacing: 4) {
                                KeyButton(labelView: AnyView(Image(systemName: "plus.rectangle.on.rectangle").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "addList"), textColor: buttonTextColor(label: "addList"), action: { model.didPressSpecialKey("addList") }, buttonWidth: buttonWidthTwo, buttonHeight: finalButtonHeight)
                                KeyButton(labelView: AnyView(Image(systemName: "trash").font(.system(size: min(buttonWidthFour, finalButtonHeight) * 0.5))), color: buttonColor(label: "removeList"), textColor: buttonTextColor(label: "removeList"), action: { model.didPressSpecialKey("removeList") }, buttonWidth: buttonWidthTwo, buttonHeight: finalButtonHeight)
                            }
                        }
                HStack(spacing: 4) {
                    makeNumberButton(label: "7", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: "8", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: "9", width: buttonWidthThree, height: finalButtonHeight)
                }
                    
                HStack(spacing: 4) {
                    makeNumberButton(label: "4", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: "5", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: "6", width: buttonWidthThree, height: finalButtonHeight)
                }
                    
                HStack(spacing: 4) {
                    makeNumberButton(label: "1", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: "2", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: "3", width: buttonWidthThree, height: finalButtonHeight)
                }
                    
                HStack(spacing: 4) {
                    makeNumberButton(label: "0", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: "00", width: buttonWidthThree, height: finalButtonHeight)
                    makeNumberButton(label: ".", width: buttonWidthThree, height: finalButtonHeight)
                }
                    
                HStack(spacing: 4) {
                    KeyButton(labelView: makeTextLabel("+/-", buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight), color: buttonColor(label: "ToggleSign"), textColor: buttonTextColor(label: "ToggleSign"), action: { buttonAction(label: "ToggleSign") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                    KeyButton(labelView: makeTextLabel("×", buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight), color: buttonColor(label: "×"), textColor: buttonTextColor(label: "×"), action: { buttonAction(label: "×") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                    KeyButton(labelView: makeTextLabel("+", buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight), color: buttonColor(label: "+"), textColor: buttonTextColor(label: "+"), action: { buttonAction(label: "+") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                }
                    
                HStack(spacing: 4) {
                    KeyButton(labelView: makeTextLabel("C", buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight), color: buttonColor(label: "C"), textColor: buttonTextColor(label: "C"), action: { buttonAction(label: "C") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                    KeyButton(labelView: makeTextLabel("÷", buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight), color: buttonColor(label: "÷"), textColor: buttonTextColor(label: "÷"), action: { buttonAction(label: "÷") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                    KeyButton(labelView: makeTextLabel("-", buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight), color: buttonColor(label: "-"), textColor: buttonTextColor(label: "-"), action: { buttonAction(label: "-") }, buttonWidth: buttonWidthThree, buttonHeight: finalButtonHeight)
                }
                    
                HStack(spacing: 4) {
                    KeyButton(labelView: makeSymbolLabel("delete.left", buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight), color: buttonColor(label: "backspace"), textColor: buttonTextColor(label: "backspace"), action: { model.didPressSpecialKey("backspace") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                    KeyButton(labelView: makeTextLabel("=", buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight), color: buttonColor(label: "="), textColor: buttonTextColor(label: "="), action: { buttonAction(label: "=") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                    KeyButton(labelView: makeSymbolLabel("arrow.uturn.backward", buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight), color: buttonColor(label: "arrow.uturn.backward"), textColor: buttonTextColor(label: "arrow.uturn.backward"), action: { buttonAction(label: "arrow.uturn.backward") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                    KeyButton(labelView: makeSymbolLabel("arrow.uturn.forward", buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight), color: buttonColor(label: "arrow.uturn.forward"), textColor: buttonTextColor(label: "arrow.uturn.forward"), action: { buttonAction(label: "arrow.uturn.forward") }, buttonWidth: buttonWidthFour, buttonHeight: finalButtonHeight)
                }
            }
            .padding(keypadPadding)
            .background(model.appThemeColor.color)
        }
    }
}

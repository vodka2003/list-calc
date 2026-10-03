import Foundation
import Combine
import SwiftUI

struct SavedFormula: Codable {
    var operation: String
    var value: String
    var memo: String?
}

enum AppThemeColor: String, CaseIterable, Identifiable {
    case defaultBlue
    case darkGray
    case classicBlack
    case purple
    case green
    case yellow
    case pink
    case brown
    case red
    case orange
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .defaultBlue:
            return "ブルー"
        case .darkGray:
            return "グレー"
        case .classicBlack:
            return "ブラック"
        case .purple:
            return "パープル"
        case .green:
            return "グリーン"
        case .yellow:
            return "イエロー"
        case .pink:
            return "ピンク"
        case .brown:
            return "ブラウン"
        case .red:
            return "レッド"
        case .orange:
            return "オレンジ"
        }
    }
    
    var color: Color {
        switch self {
        case .defaultBlue:
            return Color(red: 0.1, green: 0.3, blue: 0.6)
        case .darkGray:
            return Color(red: 0.2, green: 0.2, blue: 0.25)
        case .classicBlack:
            return Color.black
        case .purple:
            // 標準の紫だと明るすぎるため、少し暗めに調整
            return Color(red: 0.4, green: 0.2, blue: 0.6)
        case .green:
            // 標準の緑だと明るすぎるため、少し暗めに調整
            return Color(red: 0.1, green: 0.4, blue: 0.2)
        case .yellow:
            // 背景色としては眩しすぎるため、暗めのイエロー（ゴールドに近い）に調整
            return Color(red: 0.7, green: 0.5, blue: 0.0)
        case .pink:
            // 標準のピンクだと明るすぎるため、少し暗めに調整
            return Color(red: 0.8, green: 0.3, blue: 0.4)
        case .brown:
            // 標準の茶色だと濃すぎるため、少し明るめに調整
            return Color(red: 0.5, green: 0.3, blue: 0.1)
        case .red:
            // 標準の赤だと明るすぎるため、少し暗めに調整
            return Color(red: 0.7, green: 0.1, blue: 0.1)
        case .orange:
            // 標準のオレンジだと明るすぎるため、少し暗めに調整
            return Color(red: 0.9, green: 0.4, blue: 0.0)
        }
    }
}

enum LayoutDirection: String, CaseIterable, Identifiable {
    case rightHanded
    case leftHanded
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .rightHanded:
            return "右側"
        case .leftHanded:
            return "左側"
        }
    }
}

private let defaultListCountKey = "defaultListCount"
private let showMemoButtonKey = "showMemoButton"
private let showAcAllButtonKey = "showAcAllButton"
private let appThemeColorKey = "appThemeColor"
private let layoutDirectionKey = "layoutDirection"

struct MemoEditItem: Identifiable {
    let id = UUID()
    let listIndex: Int
    let lineIndex: Int
    let memo: String
}

struct CalculatorState: Codable {
    let lists: [[HistoryItem]]
    let listTotals: [String]
    let mainDisplayValue: String
    let selectedLineIndex: Int
    let selectedListIndex: Int
    let isEditing: Bool
    var isMobileMode: Bool?
}

struct HistoryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var displayValue: String = ""
    var operation: String? = nil
    var isTotal: Bool = false
    var memo: String? = nil
}

final class CalculatorModel: ObservableObject {
    private var undoStack: [CalculatorState] = []
    private var redoStack: [CalculatorState] = []
    private var clipboard: [HistoryItem]? = nil
    private var bottomClipboard: [HistoryItem]? = nil
    private let savedFormulasKey = "savedFormulas"
    private let defaultRowCount = 12
    
    @Published var memoryValue: Decimal = 0
    @Published var memoItemToEdit: MemoEditItem? = nil
    @Published var showMemoButton: Bool
    @Published var showAcAllButton: Bool
    @Published var appThemeColor: AppThemeColor
    
    @Published var mainDisplayValue: String = "0"
    @Published var listTotals: [String]
    @Published var lists: [[HistoryItem]]
    @Published var selectedListIndex: Int = 0
    @Published var layoutDirection: LayoutDirection
    @Published var savedFormulas: [String: SavedFormula] = [:]
    @Published var isMobileMode: Bool = false
    @Published var hiddenMobileLists: [Int: [HistoryItem]] = [:]
    @Published var hiddenMobileListTotals: [Int: String] = [:]
    @Published var vaultLists: [Int: [HistoryItem]] = [:]
    @Published var vaultListTotals: [Int: String] = [:]
    
    private var currentHistory: [HistoryItem] {
        get {
            guard lists.indices.contains(selectedListIndex) else { return [] }
            return lists[selectedListIndex]
        }
        set {
            guard lists.indices.contains(selectedListIndex) else { return }
            lists[selectedListIndex] = newValue
        }
    }
    
    @Published var selectedLineIndex: Int = 0
    @Published var isEditing: Bool = false
    @Published var showAcAllConfirmation: Bool = false
    var currentInputIsNew: Bool = true
    
    init() {
        let savedIsMobileMode = UserDefaults.standard.bool(forKey: "isMobileMode")
        
        let savedCount = UserDefaults.standard.integer(forKey: defaultListCountKey)
        let initialCount = (savedCount >= 2 && savedCount <= 4) ? savedCount : 2
        
        let totalCount = savedIsMobileMode ? (initialCount * 2) : initialCount
        
        let initialRows = (0..<defaultRowCount).map { _ in HistoryItem(operation: nil) }
        self.lists = Array(repeating: initialRows, count: totalCount)
        self.listTotals = Array(repeating: "0", count: totalCount)
        self.isMobileMode = savedIsMobileMode
        
        let savedShowMemoButton = UserDefaults.standard.object(forKey: showMemoButtonKey)
        self.showMemoButton = (savedShowMemoButton as? Bool) ?? true
        self.showMemoButton = (savedShowMemoButton as? Bool) ?? true
        
        let savedShowAcAllButton = UserDefaults.standard.object(forKey: showAcAllButtonKey)
        self.showAcAllButton = (savedShowAcAllButton as? Bool) ?? true
        let savedColorString = UserDefaults.standard.string(forKey: appThemeColorKey)
        self.appThemeColor = AppThemeColor(rawValue: savedColorString ?? "") ?? .darkGray
        let savedLayoutString = UserDefaults.standard.string(forKey: layoutDirectionKey)
        self.layoutDirection = LayoutDirection(rawValue: savedLayoutString ?? "") ?? .rightHanded
        
        if let data = UserDefaults.standard.data(forKey: savedFormulasKey),
           let decoded = try? JSONDecoder().decode([String: SavedFormula].self, from: data) {
            self.savedFormulas = decoded
        }
        loadAutoResumeData()
    }
    
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 100
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ","
        return formatter
    }()
    
    private func formatString(_ string: String) -> String {
        // 整数部だけを整形し、入力途中の小数部は保持する。
        let cleanString = string.replacingOccurrences(of: ",", with: "")
        
        let parts = cleanString.components(separatedBy: ".")
        
        guard let integerPart = parts.first,
              let integerNumber = numberFormatter.number(from: integerPart),
              let formattedInteger = numberFormatter.string(from: integerNumber) else {
            return string
        }
        
        if parts.count > 1 {
            return "\(formattedInteger).\(parts[1])"
        }
        
        if string.hasSuffix(".") {
            return "\(formattedInteger)."
        }
        
        return formattedInteger
    }
    
    private func finalizeCurrentNumber() {
        guard lists.indices.contains(selectedListIndex),
              lists[selectedListIndex].indices.contains(selectedLineIndex) else { return }
        
        let currentItem = currentHistory[selectedLineIndex]
        let rawValue = currentItem.displayValue.replacingOccurrences(of: ",", with: "")
        
        // 入力終了時に末尾の小数点や不要な0を正規化する。
        if let number = numberFormatter.number(from: rawValue),
           let formatted = numberFormatter.string(from: number) {
            currentHistory[selectedLineIndex].displayValue = formatted
        }
    }
    
    private func performCalculation(value1: Decimal, value2: Decimal, op: String) -> Decimal {
        switch op {
        case "+": return value1 + value2
        case "-": return value1 - value2
        case "×": return value1 * value2
        case "÷": return value2 == 0 ? 0 : value1 / value2
        default: return value2
        }
    }
    
    private func saveState() {
        let state = CalculatorState(lists: lists, listTotals: listTotals, mainDisplayValue: mainDisplayValue, selectedLineIndex: selectedLineIndex, selectedListIndex: selectedListIndex, isEditing: isEditing, isMobileMode: isMobileMode)
        undoStack.append(state)
        redoStack = []
        if undoStack.count > 50 { undoStack.removeFirst() }
    }
    
    func undo() {
        guard let previousState = undoStack.popLast() else { return }
        let currentState = CalculatorState(lists: lists, listTotals: listTotals, mainDisplayValue: mainDisplayValue, selectedLineIndex: selectedLineIndex, selectedListIndex: selectedListIndex, isEditing: isEditing, isMobileMode: isMobileMode)
        redoStack.append(currentState)
        
        lists = previousState.lists
        listTotals = previousState.listTotals
        mainDisplayValue = previousState.mainDisplayValue
        selectedLineIndex = previousState.selectedLineIndex
        selectedListIndex = previousState.selectedListIndex
        isEditing = previousState.isEditing
        self.isMobileMode = previousState.isMobileMode ?? (self.lists.count > 4)
        UserDefaults.standard.set(self.isMobileMode, forKey: "isMobileMode")
    }
    
    func redo() {
        guard let nextState = redoStack.popLast() else { return }
        let currentState = CalculatorState(lists: lists, listTotals: listTotals, mainDisplayValue: mainDisplayValue, selectedLineIndex: selectedLineIndex, selectedListIndex: selectedListIndex, isEditing: isEditing, isMobileMode: isMobileMode)
        undoStack.append(currentState)
        
        lists = nextState.lists
        listTotals = nextState.listTotals
        mainDisplayValue = nextState.mainDisplayValue
        selectedLineIndex = nextState.selectedLineIndex
        selectedListIndex = nextState.selectedListIndex
        isEditing = nextState.isEditing
        self.isMobileMode = nextState.isMobileMode ?? (self.lists.count > 4)
        UserDefaults.standard.set(self.isMobileMode, forKey: "isMobileMode")
    }
    
    func selectList(index: Int) {
        finalizeCurrentNumber()
        removePlusIfNeeded(at: selectedLineIndex)
        if lists.indices.contains(index) {
            selectedListIndex = index
            recalculateTotal()
        }
    }
    
    private func cleanupEmptyLines() {
        var itemsToReset: [Int] = []
        for i in 0..<currentHistory.count {
            if (currentHistory[i].displayValue.isEmpty || currentHistory[i].displayValue == "0") && currentHistory[i].operation != nil && i != selectedLineIndex {
                itemsToReset.append(i)
            }
        }
        for i in itemsToReset.reversed() { currentHistory[i].operation = nil }
    }
    
    func didPressNumber(_ label: String) {
        guard selectedLineIndex < currentHistory.count else { return }
        if currentInputIsNew { saveState() }
        var currentItem = currentHistory[selectedLineIndex]
        var currentValue = currentItem.displayValue.replacingOccurrences(of: ",", with: "")
        if label == "=" {
            performEquals()
            return
        }
        let currentDigitCount = currentValue.filter { $0.isNumber }.count
        if currentDigitCount >= 15 {
            if !currentInputIsNew && label != "." {
                return
            }
        }
        if currentInputIsNew {
            currentValue = (label == ".") ? "0." : label
            currentInputIsNew = false
        } else {
            if label == "00" {
                if currentDigitCount <= 13 {
                    currentValue += "00"
                } else if currentDigitCount == 14 {
                    currentValue += "0"
                }
            } else if label == "." && currentValue.contains(".") {
                return
                
            } else if currentValue == "0" && label != "." {
                currentValue = label
                
            } else if label != "." {
                currentValue += label
                
            } else if label == "." && !currentValue.contains(".") {
                currentValue += label
            }
        }
        currentItem.displayValue = formatString(currentValue)
        currentHistory[selectedLineIndex] = currentItem
        
        recalculateTotal()
        
        let updatedItem = currentHistory[selectedLineIndex]
        let operation = updatedItem.operation ?? ""
        var operatorText = ""
        
        switch operation {
        case "+", "-", "×", "÷":
            operatorText = "\(operation) "
        default:
            operatorText = ""
        }
        mainDisplayValue = operatorText + updatedItem.displayValue
    }
    
    func didPressOperator(_ label: String) {
        finalizeCurrentNumber()
        removePlusIfNeeded(at: selectedLineIndex)
        guard selectedLineIndex < currentHistory.count else { return }
        if label == "=" {
            performEquals()
            return
        }
        saveState()
        let currentItem = currentHistory[selectedLineIndex]
        let isCurrentLineEmpty = currentItem.displayValue.isEmpty || currentItem.displayValue == "0"
        
        if !isCurrentLineEmpty && !currentInputIsNew {
            let nextIndex = selectedLineIndex + 1
            ensureHistorySize(to: nextIndex)
            currentHistory[nextIndex].operation = label
            selectedLineIndex = nextIndex
        } else {
            currentHistory[selectedLineIndex].displayValue = ""
            currentHistory[selectedLineIndex].operation = label
        }
        
        currentInputIsNew = true
        recalculateTotal()
        
        mainDisplayValue = "\(label) "
    }
    
    private func performEquals() {
        finalizeCurrentNumber()
        removePlusIfNeeded(at: selectedLineIndex)
        recalculateTotal()
        saveState()
        let newIndex = currentHistory.count
        currentHistory.append(HistoryItem(operation: nil))
        selectedLineIndex = newIndex
        currentInputIsNew = true
        recalculateTotal()
    }
    
    func selectLine(index: Int) {
        finalizeCurrentNumber()
        removePlusIfNeeded(at: selectedLineIndex)
        guard !isEditing else { return }
        ensureHistorySize(to: index)
        if index < currentHistory.count {
            selectedLineIndex = index
            currentInputIsNew = true
            cleanupEmptyLines()
            recalculateTotal()
        }
    }
    
    func ensureHistorySize(to index: Int) {
        while currentHistory.count <= index {
            currentHistory.append(HistoryItem(operation: nil))
        }
    }
    
    func insertLine(after index: Int) {
        saveState()
        let insertionIndex = index
        currentHistory.insert(HistoryItem(operation: nil), at: insertionIndex)
        selectedLineIndex = insertionIndex
        currentInputIsNew = true
        recalculateTotal()
    }
    
    func deleteLine(at index: Int) { deleteLine(at: IndexSet(integer: index)) }
    func deleteLine(at offsets: IndexSet) {
        saveState()
        currentHistory.remove(atOffsets: offsets)
        if currentHistory.isEmpty {
            currentHistory.append(HistoryItem(operation: nil))
            selectedLineIndex = 0
        } else if selectedLineIndex >= currentHistory.count {
            selectedLineIndex = currentHistory.count - 1
        }
        recalculateTotal()
        currentInputIsNew = true
    }
    
    func toggleEditMode() { isEditing.toggle() }
    
    func prepareMemoEdit() {
        guard lists.indices.contains(selectedListIndex),
              lists[selectedListIndex].indices.contains(selectedLineIndex) else { return }
        
        let currentItem = lists[selectedListIndex][selectedLineIndex]
        
        self.memoItemToEdit = MemoEditItem(
            listIndex: selectedListIndex,
            lineIndex: selectedLineIndex,
            memo: currentItem.memo ?? ""
        )
    }
    
    
    func didPressSpecialKey(_ label: String) {
        switch label {
        case "arrow.uturn.backward":
            undo()
        case "arrow.uturn.forward":
            redo()
        case "backspace":
            deleteLastDigit()
        case "ToggleSign":
            toggleSign()
        case "allClear":
            showAcAllConfirmation = true
        case "addList":
            addList()
        case "removeList":
            removeList()
        case "memo":
            prepareMemoEdit()
        default:
            break
        }
    }
    
    func toggleSign() {
        guard selectedLineIndex < currentHistory.count else { return }
        saveState()
        var currentItem = currentHistory[selectedLineIndex]
        
        if currentItem.operation == "×" || currentItem.operation == "÷" {
            currentItem.operation = "-"
        }
        else {
            if currentItem.operation == "-" {
                currentItem.operation = nil
            }
            else {
                // 先頭値が負数の場合は値側の符号を外す。
                if currentItem.displayValue.hasPrefix("-") {
                    currentItem.displayValue.removeFirst()
                    currentItem.operation = nil
                } else {
                    currentItem.operation = "-"
                }
            }
        }
        
        currentHistory[selectedLineIndex] = currentItem
        
        let operation = currentItem.operation ?? ""
        var operatorText = ""
        switch operation {
        case "+", "-", "×", "÷":
            operatorText = "\(operation) "
        default:
            operatorText = ""
        }
        mainDisplayValue = currentItem.displayValue.isEmpty ? operatorText.trimmingCharacters(in: .whitespaces) : operatorText + currentItem.displayValue
        
        recalculateTotal()
    }
    
    func deleteLastDigit() {
        guard selectedLineIndex < currentHistory.count else { return }
        
        let currentValue = currentHistory[selectedLineIndex].displayValue
        
        if !currentValue.isEmpty {
            
            saveState()
            
            var newValue = currentValue.replacingOccurrences(of: ",", with: "")
            newValue.removeLast()
            
            currentHistory[selectedLineIndex].displayValue = formatString(newValue)
            
            currentInputIsNew = false
            
            recalculateTotal()
            
            let updatedItem = currentHistory[selectedLineIndex]
            let operation = updatedItem.operation ?? ""
            var operatorText = ""
            switch operation {
            case "+", "-", "×", "÷":
                operatorText = "\(operation) "
            default:
                operatorText = ""
            }
            mainDisplayValue = operatorText + updatedItem.displayValue
        }
    }
    
    func clearInput() {
        saveState()
        if selectedLineIndex < currentHistory.count {
            currentHistory[selectedLineIndex].displayValue = ""
            if selectedLineIndex > 0 {
                currentHistory[selectedLineIndex].operation = nil
            }
            recalculateTotal()
            currentInputIsNew = true
        }
    }
    
    // MARK: - Calculation
    
    private func calculateTotal(for list: [HistoryItem]) -> Decimal {
        var runningTotal: Decimal = 0
        for item in list {
            guard let value = numberFormatter.number(from: item.displayValue.replacingOccurrences(of: ",", with: ""))?.decimalValue else {
                continue
            }
            let op = item.operation ?? "+"
            runningTotal = performCalculation(value1: runningTotal, value2: value, op: op)
        }
        return runningTotal
    }
    
    private func removePlusIfNeeded(at index: Int) {
        guard lists[selectedListIndex].indices.contains(index) else { return }
        
        if lists[selectedListIndex][index].operation == "+" {
            lists[selectedListIndex][index].operation = nil
        }
    }
    
    private func recalculateTotal() {
        for (index, list) in lists.enumerated() {
            let totalDecimal = calculateTotal(for: list)
            if listTotals.indices.contains(index) {
                listTotals[index] = numberFormatter.string(for: totalDecimal) ?? "0"
            }
        }
        
        if listTotals.indices.contains(selectedListIndex) {
            mainDisplayValue = listTotals[selectedListIndex]
        }
    }
    
    
    func clearAllLists() {
        saveState()
        let totalCount = isMobileMode ? 4 : 2
        let initialRows = (0..<defaultRowCount).map { _ in HistoryItem(operation: nil) }
        lists = Array(repeating: initialRows, count: totalCount)
        listTotals = Array(repeating: "0", count: totalCount)
        selectedListIndex = 0
        selectedLineIndex = 0
        mainDisplayValue = "0"
        currentInputIsNew = true
        vaultLists.removeAll()
        vaultListTotals.removeAll()
        hiddenMobileLists.removeAll()
        hiddenMobileListTotals.removeAll()
    }
    
    func clearAll() {
        clearAllLists()
    }
    
    func clearList(at index: Int) {
        saveState()
        guard lists.indices.contains(index) else { return }
        lists[index] = [HistoryItem(operation: nil)]
        if selectedListIndex == index {
            selectedLineIndex = 0
        }
        recalculateTotal()
    }
    
    func getCurrentState() -> CalculatorState {
        return CalculatorState(
            lists: self.lists,
            listTotals: self.listTotals,
            mainDisplayValue: self.mainDisplayValue,
            selectedLineIndex: self.selectedLineIndex,
            selectedListIndex: self.selectedListIndex,
            isEditing: self.isEditing,
            isMobileMode: self.isMobileMode
        )
    }
    
    func loadState(_ state: CalculatorState) {
        self.lists = state.lists
        self.listTotals = state.listTotals
        self.mainDisplayValue = state.mainDisplayValue
        self.selectedLineIndex = state.selectedLineIndex
        self.selectedListIndex = state.selectedListIndex
        self.isEditing = state.isEditing
        self.isMobileMode = state.isMobileMode ?? (self.lists.count > 4)
        UserDefaults.standard.set(self.isMobileMode, forKey: "isMobileMode")
    }
    
    func setMemo(listIndex: Int, lineIndex: Int, memo: String) {
        guard lists.indices.contains(listIndex),
              lists[listIndex].indices.contains(lineIndex) else { return }
        saveState()
        let newMemo = memo.isEmpty ? nil : memo
        lists[listIndex][lineIndex].memo = newMemo
    }
    
    func addList() {
        let colCount = isMobileMode ? (lists.count / 2) : lists.count
        
        if colCount < 4 {
            saveState()
            let emptyRows = (0..<defaultRowCount).map { _ in HistoryItem(operation: nil) }
            if isMobileMode {
                let topIndex = colCount
                let bottomIndex = (colCount * 2) + 1
                
                let restoredTop = refreshIDs(for: vaultLists[topIndex] ?? emptyRows)
                let restoredTopTotal = vaultListTotals[topIndex] ?? "0"
                let restoredBottom = refreshIDs(for: vaultLists[bottomIndex] ?? emptyRows)
                let restoredBottomTotal = vaultListTotals[bottomIndex] ?? "0"
                
                lists.insert(restoredTop, at: topIndex)
                listTotals.insert(restoredTopTotal, at: topIndex)
                lists.append(restoredBottom)
                listTotals.append(restoredBottomTotal)
                
                if selectedListIndex >= colCount {
                    selectedListIndex += 1
                }
            } else {
                let topIndex = colCount
                
                let restoredTop = refreshIDs(for: vaultLists[topIndex] ?? emptyRows)
                let restoredTopTotal = vaultListTotals[topIndex] ?? "0"
                
                lists.append(restoredTop)
                listTotals.append(restoredTopTotal)
            }
        }
    }
    
    func removeList() {
        let colCount = isMobileMode ? (lists.count / 2) : lists.count
        
        if colCount > 2 {
            saveState()
            if isMobileMode {
                if selectedListIndex == (colCount * 2) - 1 {
                    selectedListIndex -= 2
                } else if selectedListIndex >= colCount {
                    selectedListIndex -= 1
                } else if selectedListIndex == colCount - 1 {
                    selectedListIndex -= 1
                }
                
                let topIndex = colCount - 1
                let bottomIndex = (colCount * 2) - 1
                
                // 削除した列を再追加時の復元用に退避する。
                vaultLists[topIndex] = lists[topIndex]
                vaultListTotals[topIndex] = listTotals[topIndex]
                vaultLists[bottomIndex] = lists[bottomIndex]
                vaultListTotals[bottomIndex] = listTotals[bottomIndex]
                
                lists.removeLast()
                listTotals.removeLast()
                lists.remove(at: topIndex)
                listTotals.remove(at: topIndex)
            } else {
                let topIndex = colCount - 1
                
                // 削除した列を再追加時の復元用に退避する。
                vaultLists[topIndex] = lists[topIndex]
                vaultListTotals[topIndex] = listTotals[topIndex]
                
                lists.removeLast()
                listTotals.removeLast()
                if selectedListIndex >= lists.count {
                    selectedListIndex = lists.count - 1
                }
            }
        }
    }
    
    func copyList(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        
        guard lists.indices.contains(sourceIndex),
              lists.indices.contains(destinationIndex) else { return }
        
        saveState()
        
        lists[destinationIndex] = lists[sourceIndex]
        
        // 2段表示では対応する下段リストも同時にコピーする。
        if isMobileMode {
            let colCount = lists.count / 2
            let sourceBottomIndex = sourceIndex + colCount
            let destBottomIndex = destinationIndex + colCount
            
            if lists.indices.contains(sourceBottomIndex) && lists.indices.contains(destBottomIndex) {
                lists[destBottomIndex] = lists[sourceBottomIndex]
            }
        }
        
        recalculateTotal()
    }
    
    func copyList(at index: Int) {
        guard lists.indices.contains(index) else { return }
        
        clipboard = lists[index]
        
        // 2段表示では対応する下段リストも保持する。
        if isMobileMode {
            let colCount = lists.count / 2
            let bottomIndex = index + colCount
            
            if lists.indices.contains(bottomIndex) {
                bottomClipboard = lists[bottomIndex]
            }
        } else {
            bottomClipboard = nil
        }
    }
    
    func pasteList(at index: Int) {
        guard let copiedList = clipboard else { return }
        guard lists.indices.contains(index) else { return }
        
        saveState()
        
        lists[index] = copiedList
        
        // 2段表示では対応する下段リストも貼り付ける。
        if isMobileMode {
            let colCount = lists.count / 2
            let bottomIndex = index + colCount
            
            if let bottomCopied = bottomClipboard, lists.indices.contains(bottomIndex) {
                lists[bottomIndex] = bottomCopied
            }
        }
        
        recalculateTotal()
    }
    
    func getDefaultListCount() -> Int {
        let count = UserDefaults.standard.integer(forKey: defaultListCountKey)
        return (count >= 2 && count <= 4) ? count : 2
    }
    
    func setDefaultListCount(count: Int) {
        guard count >= 2 && count <= 4 else { return }
        UserDefaults.standard.set(count, forKey: defaultListCountKey)
    }
    func getShowMemoButton() -> Bool {
        return self.showMemoButton
    }
    
    func setShowMemoButton(isOn: Bool) {
        self.showMemoButton = isOn
        
        UserDefaults.standard.set(isOn, forKey: showMemoButtonKey)
    }
    
    func getShowAcAllButton() -> Bool {
        return self.showAcAllButton
    }
    
    func setShowAcAllButton(isOn: Bool) {
        self.showAcAllButton = isOn
        
        UserDefaults.standard.set(isOn, forKey: showAcAllButtonKey)
    }
    func getAppThemeColor() -> AppThemeColor {
        return self.appThemeColor
    }
    
    func setAppThemeColor(color: AppThemeColor) {
        self.appThemeColor = color
        
        UserDefaults.standard.set(color.rawValue, forKey: appThemeColorKey)
    }
    func getLayoutDirection() -> LayoutDirection {
        return self.layoutDirection
    }
    
    func setLayoutDirection(_ direction: LayoutDirection) {
        self.layoutDirection = direction
        
        UserDefaults.standard.set(direction.rawValue, forKey: layoutDirectionKey)
    }
    
    func saveFormula(key: String, operation: String, value: String, memo: String?) {
        let formula = SavedFormula(operation: operation, value: value, memo: memo)
        savedFormulas[key] = formula
        
        if let encoded = try? JSONEncoder().encode(savedFormulas) {
            UserDefaults.standard.set(encoded, forKey: savedFormulasKey)
        }
    }
    
    func executeShortcut(key: String) {
        guard let formula = savedFormulas[key] else { return }
        
        saveState()
        if selectedLineIndex > 0 {
            removePlusIfNeeded(at: selectedLineIndex - 1)
        }
        currentHistory.insert(HistoryItem(operation: nil), at: selectedLineIndex)
        
        if formula.operation == "+" {
            currentHistory[selectedLineIndex].operation = nil
        } else {
            currentHistory[selectedLineIndex].operation = formula.operation
        }
        currentHistory[selectedLineIndex].displayValue = formatString(formula.value)
        currentHistory[selectedLineIndex].memo = formula.memo
        
        if selectedLineIndex == 0 && currentHistory[selectedLineIndex].operation == "+" {
            currentHistory[selectedLineIndex].operation = nil
        }
        
        selectedLineIndex += 1
        
        if selectedLineIndex >= currentHistory.count {
            currentHistory.append(HistoryItem(operation: nil))
        }
        
        currentInputIsNew = true
        recalculateTotal()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    func saveAutoResumeData() {
        if let encoded = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(encoded, forKey: "autoResumeLists")
        }
        UserDefaults.standard.set(selectedListIndex, forKey: "autoResumeListIndex")
        
        UserDefaults.standard.set(mainDisplayValue, forKey: "autoResumeMainDisplay")
    }
    
    func loadAutoResumeData() {
        if let savedData = UserDefaults.standard.data(forKey: "autoResumeLists"),
           let decodedLists = try? JSONDecoder().decode([[HistoryItem]].self, from: savedData) {
            self.lists = decodedLists
            self.listTotals = Array(repeating: "0", count: decodedLists.count)
            self.recalculateTotal()
        }
        
        self.selectedListIndex = UserDefaults.standard.integer(forKey: "autoResumeListIndex")
        
        if let savedDisplay = UserDefaults.standard.string(forKey: "autoResumeMainDisplay") {
            self.mainDisplayValue = savedDisplay
        }
    }
    // SwiftUIが復元前後の行を同一要素として扱わないようIDを更新する。
    private func refreshIDs(for list: [HistoryItem]) -> [HistoryItem] {
        return list.map { item in
            var newItem = item
            newItem.id = UUID()
            return newItem
        }
    }

    // MARK: - Mobile Mode
    func toggleMobileMode() {
        withAnimation(nil) {
            saveState()
            isMobileMode.toggle()
            UserDefaults.standard.set(isMobileMode, forKey: "isMobileMode")
            
            let colCount = isMobileMode ? lists.count : (lists.count / 2)
            
            if isMobileMode {
                var newBottomLists: [[HistoryItem]] = []
                var newBottomTotals: [String] = []
                
                for i in 0..<colCount {
                    if let saved = hiddenMobileLists[i] {
                        newBottomLists.append(refreshIDs(for: saved))
                        newBottomTotals.append(hiddenMobileListTotals[i] ?? "0")
                    } else {
                        newBottomLists.append([HistoryItem(operation: nil)])
                        newBottomTotals.append("0")
                    }
                    hiddenMobileLists.removeValue(forKey: i)
                    hiddenMobileListTotals.removeValue(forKey: i)
                }
                
                lists.append(contentsOf: newBottomLists)
                listTotals.append(contentsOf: newBottomTotals)
                
            } else {
                for i in 0..<colCount {
                    hiddenMobileLists[i] = lists[colCount + i]
                    hiddenMobileListTotals[i] = listTotals[colCount + i]
                }
                
                lists.removeLast(colCount)
                listTotals.removeLast(colCount)
                
                if selectedListIndex >= colCount {
                    selectedListIndex -= colCount
                }
            }
        }
    }
}

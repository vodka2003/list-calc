import SwiftUI

// MARK: - SingleHistoryView
struct SingleHistoryView: View {
    @ObservedObject var model: CalculatorModel
    let listIndex: Int
    private let rowHeight: CGFloat = 45
    
    @ViewBuilder
    private func historyItemsList(currentList: [HistoryItem]) -> some View {
        ForEach(Array(currentList.enumerated()), id: \.element.id) { index, item in
            let isSelected = (model.selectedListIndex == listIndex && model.selectedLineIndex == index)
            
            HistoryRowView(
                item: item,
                isSelected: isSelected,
                isCurrentlyEditing: !model.currentInputIsNew
            )
            .onTapGesture {
                model.selectList(index: listIndex)
                model.selectLine(index: index)
            }
            .onLongPressGesture {
                model.selectList(index: listIndex)
                model.insertLine(after: index)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    model.selectList(index: listIndex)
                    model.deleteLine(at: index)
                } label: {
                    Label("削除", systemImage: "trash.fill")
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(
                isSelected ? Color.yellow.opacity(0.3) : Color.white
            )
        }
    }
    
    @ViewBuilder
    private func fillerRowsList(fillerRowCount: Int, currentListCount: Int) -> some View {
        if fillerRowCount > 0 {
            ForEach(0..<fillerRowCount, id: \.self) { i in
                VStack(spacing: 0) {
                    Color.clear.frame(height: rowHeight - 1)
                    Divider().overlay(Color.gray)
                }
                .frame(height: rowHeight)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .contentShape(Rectangle())
                .onTapGesture {
                    let emptyRowIndex = currentListCount + i
                    model.selectList(index: listIndex)
                    model.selectLine(index: emptyRowIndex)
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            if model.lists.indices.contains(listIndex) {
                let numVisibleRows = Int(geometry.size.height / rowHeight)
                let currentList = model.lists[listIndex]
                let fillerRowCount = numVisibleRows - currentList.count
                
                List {
                    historyItemsList(currentList: currentList)
                    fillerRowsList(fillerRowCount: fillerRowCount, currentListCount: currentList.count)
                }
                .listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 0)
            } else {
                Color.gray.opacity(0.1)
            }
        }
        .border(Color.black, width: 1)
        .background(Color.white)
    }
}

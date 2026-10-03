import SwiftUI

// MARK: - HistoryRowView
struct HistoryRowView: View {
    let item: HistoryItem
    let isSelected: Bool
    let isCurrentlyEditing: Bool
    
    private var opText: String {
        guard let operation = item.operation else { return "" }
        
        switch operation {
        case "+", "-", "×", "÷":
            return operation
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if let memo = item.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.5)
                } else {
                    Spacer(minLength: 0)
                }
                
                Text(opText)
                    .font(.title).fontWeight(.regular)
                    .foregroundColor(item.operation == "-" ? .red : .black)
                    .minimumScaleFactor(0.5)
                
                Text(item.displayValue)
                    .font(.title).fontWeight(.regular)
                    .foregroundColor(item.operation == "-" || item.displayValue.hasPrefix("-") ? .red : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .layoutPriority(1)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            Divider().overlay(Color.gray)
        }
        .frame(height: 45)
        .contentShape(Rectangle())
    }
}

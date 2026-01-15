import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let date: String
    let imageName: String
}

struct TransactionListView: View {
    let transactions = [
        Transaction(name: "Kwame Diamini", amount: -10.00, date: "Today", imageName: "person.circle.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Text("Today")
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            // Transaction List
            ForEach(transactions) { transaction in
                TransactionRow(transaction: transaction)
                    .padding(.horizontal, 20)
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 14) {
            // Profile Image
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .pink.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                )
            
            // Name
            Text(transaction.name)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Amount
            Text(String(format: "-£%.2f", abs(transaction.amount)))
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    TransactionListView()
}

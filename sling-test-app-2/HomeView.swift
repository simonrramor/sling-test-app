import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Balance
            BalanceView()
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // Transactions
            TransactionListView()
                .padding(.top, 20)
            
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}

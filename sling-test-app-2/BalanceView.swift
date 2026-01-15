import SwiftUI

struct BalanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Balance")
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(.gray)
            
            Text("$2,541.01")
                .font(.custom("Inter-Bold", size: 36))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }
}

#Preview {
    BalanceView()
        .padding()
}

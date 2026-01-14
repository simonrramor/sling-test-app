import SwiftUI

struct BalanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Balance")
                .font(.custom("Inter18pt-Regular", size: 16))
                .foregroundColor(.gray)
            
            Text("$2,541.01")
                .font(.custom("Inter18pt-Bold", size: 36))
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

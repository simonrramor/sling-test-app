import SwiftUI

struct TransferAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
}

struct TransferView: View {
    let actions = [
        TransferAction(
            title: "Send",
            subtitle: "Pay anyone on Sling in seconds",
            iconName: "TransferSend"
        ),
        TransferAction(
            title: "Request",
            subtitle: "Ask someone to pay you back",
            iconName: "TransferRequest"
        ),
        TransferAction(
            title: "Transfer",
            subtitle: "Move money between your accounts",
            iconName: "TransferTransfer"
        ),
        TransferAction(
            title: "Withdraw",
            subtitle: "Bank, card or mobile money",
            iconName: "TransferWithdraw"
        ),
        TransferAction(
            title: "Receive your salary",
            subtitle: "Get paid into Sling",
            iconName: "TransferSalary"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(actions) { action in
                TransferActionRow(action: action)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 16)
    }
}

struct TransferActionRow: View {
    let action: TransferAction
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                // Icon from Figma
                Image(action.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                
                // Text content
                VStack(alignment: .leading, spacing: 0) {
                    Text(action.title)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                    
                    Text(action.subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
                
                Spacer()
            }
            .padding(16)
        }
    }
}

#Preview {
    TransferView()
}

import SwiftUI

struct TransferAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    let backgroundColor: Color
}

struct TransferView: View {
    let actions = [
        TransferAction(
            title: "Send",
            subtitle: "Pay anyone on Sling in seconds",
            iconName: "paperplane.fill",
            iconColor: Color(hex: "74CDFF"),
            backgroundColor: Color(hex: "E8F8FF")
        ),
        TransferAction(
            title: "Request",
            subtitle: "Ask someone to pay you back",
            iconName: "arrow.down.circle.fill",
            iconColor: Color(hex: "78D381"),
            backgroundColor: Color(hex: "E9FAEB")
        ),
        TransferAction(
            title: "Transfer",
            subtitle: "Move money between your accounts",
            iconName: "arrow.left.arrow.right",
            iconColor: Color(hex: "FF74E0"),
            backgroundColor: Color(hex: "FFE8F9")
        ),
        TransferAction(
            title: "Withdraw",
            subtitle: "Bank, card or mobile money",
            iconName: "arrow.down.to.line",
            iconColor: Color(hex: "9874FF"),
            backgroundColor: Color(hex: "F2ECFF")
        ),
        TransferAction(
            title: "Receive your salary",
            subtitle: "Get paid into Sling",
            iconName: "banknote.fill",
            iconColor: Color(hex: "7B7B7B"),
            backgroundColor: Color(hex: "F7F7F7")
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
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(action.backgroundColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: action.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(action.iconColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 0) {
                    Text(action.title)
                        .font(.custom("Inter18pt-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                    
                    Text(action.subtitle)
                        .font(.custom("Inter18pt-Regular", size: 14))
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

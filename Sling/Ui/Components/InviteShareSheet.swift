import SwiftUI
import UIKit

struct InviteShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    
    let referralLink = "https://sling.money/invite/brendon"
    let referralMessage = "Join me on Sling! Send money instantly to friends anywhere in the world. Use my link to sign up and we'll both get rewards."
    
    var body: some View {
        VStack(spacing: 24) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
            
            // Header
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF5113").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "gift.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "FF5113"))
                }
                
                Text("Invite Friends")
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text("Share Sling with friends and earn rewards when they sign up.")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(themeService.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Referral link box
            HStack {
                Text(referralLink)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = referralLink
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                }
            }
            .padding(16)
            .background(Color(hex: "F7F7F7"))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            // Share buttons
            VStack(spacing: 12) {
                Button(action: {
                    shareViaSystem()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share Link")
                            .font(.custom("Inter-Bold", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "080808"))
                    .cornerRadius(16)
                }
                
                Button(action: {
                    shareViaMessages()
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Send via Messages")
                            .font(.custom("Inter-Bold", size: 16))
                    }
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "EDEDED"))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
    
    private func shareViaSystem() {
        let activityVC = UIActivityViewController(
            activityItems: [referralMessage, URL(string: referralLink)!],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func shareViaMessages() {
        let sms = "sms:&body=\(referralMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: sms) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    InviteShareSheet()
}

import SwiftUI

struct NotificationBanner: View {
    @ObservedObject private var themeService = ThemeService.shared
    let notification: InAppNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: notification.type.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: notification.type.color))
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                
                if !notification.message.isEmpty {
                    Text(notification.message)
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(themeService.textSecondaryColor)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeService.textSecondaryColor)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

struct NotificationOverlay: View {
    @ObservedObject var notificationService = NotificationService.shared
    
    var body: some View {
        VStack {
            if let notification = notificationService.currentNotification {
                NotificationBanner(
                    notification: notification,
                    onDismiss: {
                        notificationService.dismiss()
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: notificationService.currentNotification)
    }
}

#Preview {
    VStack {
        NotificationBanner(
            notification: InAppNotification(
                title: "Payment Received",
                message: "Ben Johnson sent you £25.00",
                type: .success
            ),
            onDismiss: {}
        )
        
        NotificationBanner(
            notification: InAppNotification(
                title: "New Request",
                message: "Eileen Farrell requested £12.50",
                type: .request
            ),
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

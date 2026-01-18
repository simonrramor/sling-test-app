import SwiftUI

struct ActivityView: View {
    @StateObject private var activityService = ActivityService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Activity Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity")
                        .font(.custom("Inter-Bold", size: 24))
                        .foregroundColor(Color(hex: "080808"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                if activityService.isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading activity...")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else if activityService.activities.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Text("No recent activity")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    // Activity list
                    VStack(spacing: 0) {
                        ForEach(activityService.activities) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                Spacer()
            }
        }
        .onAppear {
            Task {
                await activityService.fetchActivities()
            }
        }
        .refreshable {
            await activityService.fetchActivities()
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    @GestureState private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ActivityAvatar(identifier: activity.avatar)
            
            // Left content (title and subtitle)
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.titleLeft)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                if !activity.subtitleLeft.isEmpty {
                    Text(activity.subtitleLeft)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
            }
            
            Spacer()
            
            // Right content (amount and date/status)
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.titleRight)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(activity.titleRight.hasPrefix("-") ? Color(hex: "E30000") : Color(hex: "080808"))
                
                if !activity.subtitleRight.isEmpty {
                    Text(activity.subtitleRight)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color(hex: "F7F7F7") : Color.clear)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
    }
}

struct ActivityAvatar: View {
    let identifier: String
    
    var body: some View {
        // Check if it's an image name or initials
        if identifier.count <= 2 {
            // Initials
            ZStack {
                Circle()
                    .fill(Color(hex: "EDEDED"))
                    .frame(width: 44, height: 44)
                
                Text(identifier.uppercased())
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
            }
        } else if identifier.hasPrefix("http") {
            // URL - async image
            AsyncImage(url: URL(string: identifier)) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color(hex: "EDEDED"))
                        .frame(width: 44, height: 44)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(Color(hex: "EDEDED"))
                        .frame(width: 44, height: 44)
                @unknown default:
                    Circle()
                        .fill(Color(hex: "EDEDED"))
                        .frame(width: 44, height: 44)
                }
            }
        } else {
            // Asset name
            Image(identifier)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ActivityView()
}

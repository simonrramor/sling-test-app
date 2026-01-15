import SwiftUI

struct ActivityView: View {
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
                
                // Placeholder content
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
                
                Spacer()
            }
        }
    }
}

#Preview {
    ActivityView()
}

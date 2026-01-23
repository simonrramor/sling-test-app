import SwiftUI
import UIKit
import LocalAuthentication

struct SpendCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let iconName: String
    let iconColor: Color
}

struct SpendView: View {
    @State private var isCardLocked = false
    @State private var showCardDetails = false
    @AppStorage("hasCard") private var hasCard = false
    @ObservedObject private var themeService = ThemeService.shared
    
    // Shadow control sliders
    @State private var shadowOpacity: Double = 0.25
    @State private var shadowRadius: Double = 20
    @State private var shadowOffsetX: Double = 0
    @State private var shadowOffsetY: Double = 10
    @State private var showShadowControls = false
    @State private var showSubscriptions = false
    
    let categories = [
        SpendCategory(name: "Groceries", amount: "$1,032", iconName: "cart.fill", iconColor: Color(hex: "78D381")),
        SpendCategory(name: "Transport", amount: "$1,032", iconName: "car.fill", iconColor: Color(hex: "74CDFF")),
        SpendCategory(name: "Shopping", amount: "$1,032", iconName: "bag.fill", iconColor: Color(hex: "FFC774"))
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if hasCard {
                    // Card content
                    cardContent
                } else {
                    // Empty state
                    VStack(spacing: 0) {
                        // Card illustration from Figma
                        Image("CardEmptyIllustration")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                        
                        CardEmptyStateCard(onGetCard: {
                            withAnimation {
                                hasCard = true
                            }
                        })
                        .padding(.horizontal, 24)
                    }
                }
                
                // Bottom padding for scroll content to clear nav bar
                Spacer()
                    .frame(height: 120)
            }
        }
        .background(themeService.backgroundColor)
        .sheet(isPresented: $showCardDetails) {
            CardDetailsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.white)
        }
        .sheet(isPresented: $showSubscriptions) {
            SubscriptionsSheet()
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // 3D Interactive Card
            Card3DView(isLocked: $isCardLocked, cameraFOV: 40.1, backgroundColor: themeService.backgroundColor, onTap: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showShadowControls.toggle()
                }
            })
            .frame(height: 240)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .overlay(
                Group {
                    if isCardLocked {
                        // Lock icon in center
                        Image("LockLockedIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }
                }
            )
            .padding(.top, 16)
            
            // Shadow Controls
            if showShadowControls {
                VStack(spacing: 12) {
                    HStack {
                        Text("Shadow Controls")
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Spacer()
                        Button(action: {
                            withAnimation { showShadowControls = false }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeService.textTertiaryColor)
                        }
                    }
                    
                    ShadowSlider(label: "Opacity", value: $shadowOpacity, range: 0...1, format: "%.2f")
                    ShadowSlider(label: "Radius", value: $shadowRadius, range: 0...50, format: "%.0f")
                    ShadowSlider(label: "Offset X", value: $shadowOffsetX, range: -30...30, format: "%.0f")
                    ShadowSlider(label: "Offset Y", value: $shadowOffsetY, range: -30...30, format: "%.0f")
                }
                .padding(16)
                .background(themeService.backgroundSecondaryColor)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            
            HStack(spacing: 8) {
                TertiaryButton(title: "Show details") {
                    authenticateAndShowDetails()
                }
                
                TertiaryButton(title: isCardLocked ? "Unlock" : "Lock") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCardLocked.toggle()
                    }
                } icon: {
                    ZStack {
                        Image("LockIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .opacity(isCardLocked ? 0 : 1)
                            .scaleEffect(isCardLocked ? 0.8 : 1)
                        
                        Image("LockLockedIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .opacity(isCardLocked ? 1 : 0)
                            .scaleEffect(isCardLocked ? 1 : 0.8)
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCardLocked)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Spent this month (1st Dec – 1st Jan)")
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text("$3,430")
                    .font(.custom("Inter-Bold", size: 33))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeService.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { category in
                        CategoryCard(category: category)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 8)
            
            // Subscriptions card - tappable
            Button(action: {
                showSubscriptions = true
            }) {
                HStack(spacing: 16) {
                    // Overlapping subscription avatars
                    HStack(spacing: -23) {
                        Image("SubscriptionDisney")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .zIndex(0)
                        
                        Image("SubscriptionNetflix")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .zIndex(1)
                        
                        Image("SubscriptionAppleTV")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .zIndex(2)
                    }
                    
                    Text("Track your subscriptions")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "080808").opacity(0.3))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    // MARK: - Biometric Authentication
    
    private func authenticateAndShowDetails() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to view your card details"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        showCardDetails = true
                    } else {
                        // Biometric failed, try device passcode as fallback
                        authenticateWithPasscode()
                    }
                }
            }
        } else {
            // Biometrics not available, fall back to device passcode
            authenticateWithPasscode()
        }
    }
    
    private func authenticateWithPasscode() {
        let context = LAContext()
        let reason = "Authenticate to view your card details"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    showCardDetails = true
                }
                // If passcode also fails, just don't show details (user cancelled or failed)
            }
        }
    }
}

// MARK: - Card Empty State

struct CardEmptyStateCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    var onGetCard: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Text content
            VStack(spacing: 8) {
                Text("Create your Sling Card today")
                    .font(.custom("Inter-Bold", size: 32))
                    .tracking(-0.64)
                    .lineSpacing(1)
                    .foregroundColor(themeService.textPrimaryColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 313)
                
                Text("Get your new virtual debit card, and start spending digital dollars around the world, with no fees.")
                    .font(.custom("Inter-Regular", size: 16))
                    .tracking(-0.32)
                    .lineSpacing(8)
                    .foregroundColor(themeService.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
            
            // Create card button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onGetCard()
            }) {
                Text("Create Sling Card")
                    .font(.custom("Inter-Bold", size: 16))
                    .tracking(-0.32)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "000000"))
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}

struct CategoryCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let category: SpendCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            RoundedRectangle(cornerRadius: 7)
                .fill(category.iconColor)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: category.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text(category.amount)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeService.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
        )
    }
}


// MARK: - Card Details Sheet

struct CardDetailsSheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Mock card data
    let cardDetails = [
        CardDetailRow(title: "Name on card", value: "John Taylor"),
        CardDetailRow(title: "Card number", value: "4532 1234 5678 9012"),
        CardDetailRow(title: "Expiry date", value: "10/29"),
        CardDetailRow(title: "CVV", value: "123"),
        CardDetailRow(title: "Billing address", value: "1801 Main St.\nKansas City\nMO 64108")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Card detail rows
            VStack(spacing: 8) {
                ForEach(cardDetails) { detail in
                    CardDetailField(title: detail.title, value: detail.value)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
            
            Spacer()
        }
        .background(Color.white)
    }
}

struct CardDetailRow: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct CardDetailField: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    let value: String
    @State private var copied = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundColor(themeService.textTertiaryColor)
                
                Text(value)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            
            Spacer()
            
            // Copy button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                UIPasteboard.general.string = value.replacingOccurrences(of: "\n", with: ", ")
                copied = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    copied = false
                }
            }) {
                ZStack {
                    Image(systemName: copied ? "checkmark" : "square.on.square")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(copied ? Color(hex: "57CE43") : themeService.textPrimaryColor.opacity(0.8))
                }
                .frame(width: 24, height: 24)
            }
            .contentShape(Rectangle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "FCFCFC"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "F7F7F7"), lineWidth: 1)
        )
    }
}

// MARK: - Shadow Slider

struct ShadowSlider: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundColor(themeService.textSecondaryColor)
                Spacer()
                Text(String(format: format, value))
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(width: 50, alignment: .trailing)
            }
            Slider(value: $value, in: range)
                .tint(Color(hex: "FF5113"))
        }
    }
}

// MARK: - Subscription Model

struct Subscription: Identifiable {
    let id = UUID()
    let name: String
    let dayOfMonth: Int
    let imageName: String? // Asset image name
    let fallbackColor: String // Fallback color if no image
}

// MARK: - Subscriptions Sheet

struct SubscriptionsSheet: View {
    var body: some View {
        VStack(spacing: 0) {
            // Calendar
            SubscriptionCalendarView()
                .padding(.horizontal, 24)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .presentationBackground(Color.white)
    }
}

// MARK: - Subscription Calendar View

struct SubscriptionCalendarView: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    private let calendar = Calendar.current
    private let today = Date()
    
    // Sample subscriptions dotted throughout the month
    private let subscriptions: [Subscription] = [
        Subscription(name: "Spotify", dayOfMonth: 1, imageName: "SubscriptionSpotify", fallbackColor: "1DB954"),
        Subscription(name: "Netflix", dayOfMonth: 8, imageName: "SubscriptionNetflix", fallbackColor: "E50914"),
        Subscription(name: "Apple Music", dayOfMonth: 12, imageName: "SubscriptionAppleMusic", fallbackColor: "FC3C44"),
        Subscription(name: "Hulu", dayOfMonth: 15, imageName: "SubscriptionHulu", fallbackColor: "1CE783"),
        Subscription(name: "Disney+", dayOfMonth: 20, imageName: "SubscriptionDisney", fallbackColor: "113CCF"),
        Subscription(name: "Apple TV", dayOfMonth: 25, imageName: "SubscriptionAppleTV", fallbackColor: "000000")
    ]
    
    private func subscription(for day: Int) -> Subscription? {
        subscriptions.first { $0.dayOfMonth == day }
    }
    
    private var currentMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = currentMonth
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        // Adjust for Monday start (weekday 1 = Sunday, so Monday = 2)
        let offset = (firstWeekday + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.custom("Inter-Medium", size: 12))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            let cellWidth: CGFloat = 44
            let cellHeight: CGFloat = 56
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        let dayNumber = calendar.component(.day, from: date)
                        let isToday = calendar.isDateInToday(date)
                        let sub = subscription(for: dayNumber)
                        
                        VStack(spacing: 8) {
                            // Subscription indicator at top (or spacer if none)
                            if let sub = sub {
                                if let imageName = sub.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 12, height: 12)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.06), lineWidth: 0.67)
                                        )
                                } else {
                                    Circle()
                                        .fill(Color(hex: sub.fallbackColor))
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.06), lineWidth: 0.67)
                                        )
                                }
                            } else {
                                Spacer()
                                    .frame(height: 12)
                            }
                            
                            // Date number at bottom
                            Text("\(dayNumber)")
                                .font(.custom(isToday ? "Inter-Bold" : "Inter-Medium", size: 16))
                                .foregroundColor(isToday ? .white : themeService.textPrimaryColor)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                        .frame(width: cellWidth, height: cellHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isToday ? Color(hex: "080808") : Color(hex: "F5F5F5"))
                        )
                    } else {
                        Color.clear
                            .frame(width: cellWidth, height: cellHeight)
                    }
                }
            }
        }
    }
}

#Preview {
    SpendView()
}
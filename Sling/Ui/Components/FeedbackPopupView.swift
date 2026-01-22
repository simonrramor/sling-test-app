import SwiftUI
import UIKit

struct FeedbackPopupView: View {
    @ObservedObject private var feedbackManager = FeedbackModeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var feedbackText = ""
    @State private var selectedCategory: FeedbackCategory? = nil
    @State private var selectedTeam: FeedbackTeam? = nil
    @State private var isSubmitting = false
    @State private var showSuccessMessage = false
    @State private var errorMessage: String? = nil
    
    @FocusState private var isTextFieldFocused: Bool
    
    enum FeedbackCategory {
        case product
        case design
        case dev
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Screenshot preview
                    if let screenshot = feedbackManager.currentFeedback.screenshot {
                        screenshotPreview(screenshot)
                    }
                    
                    // Feedback text field
                    feedbackTextField
                    
                    // Team selection
                    teamSelection
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Submit button
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.white)
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        feedbackManager.resetFeedback()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .interactiveDismissDisabled(isSubmitting)
        .overlay {
            if showSuccessMessage {
                successOverlay
            }
        }
    }
    
    // MARK: - Screenshot Preview
    
    private func screenshotPreview(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screenshot")
                .font(.custom("Inter-Bold", size: 14))
                .foregroundColor(.gray)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Feedback Text Field
    
    private var feedbackTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Feedback")
                .font(.custom("Inter-Bold", size: 14))
                .foregroundColor(.gray)
            
            TextEditor(text: $feedbackText)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(.black)
                .frame(minHeight: 120)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .focused($isTextFieldFocused)
            
            Text("Describe what you'd like to change or report")
                .font(.custom("Inter-Regular", size: 12))
                .foregroundColor(.gray.opacity(0.8))
        }
    }
    
    // MARK: - Team Selection
    
    private var teamSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Send to")
                .font(.custom("Inter-Bold", size: 14))
                .foregroundColor(.gray)
            
            // Primary categories
            HStack(spacing: 12) {
                categoryButton(.product, title: "Product", icon: "lightbulb.fill", color: .purple)
                categoryButton(.design, title: "Design", icon: "paintbrush.fill", color: .pink)
                categoryButton(.dev, title: "Dev", icon: "hammer.fill", color: .blue)
            }
            
            // Dev sub-options
            if selectedCategory == .dev {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Development Team")
                        .font(.custom("Inter-Bold", size: 12))
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.top, 4)
                    
                    HStack(spacing: 12) {
                        devTeamButton(.devFrontend, title: "Front End", subtitle: "Marius")
                        devTeamButton(.devBackend, title: "Back End", subtitle: "Dom")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedCategory)
    }
    
    private func categoryButton(_ category: FeedbackCategory, title: String, icon: String, color: Color) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            if selectedCategory == category {
                // Deselect if already selected
                selectedCategory = nil
                selectedTeam = nil
            } else {
                selectedCategory = category
                // Auto-select team for non-dev categories
                switch category {
                case .product:
                    selectedTeam = .product
                case .design:
                    selectedTeam = .design
                case .dev:
                    selectedTeam = nil // Require sub-selection
                }
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(selectedCategory == category ? color : color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(selectedCategory == category ? .white : color)
                }
                
                Text(title)
                    .font(.custom("Inter-Bold", size: 13))
                    .foregroundColor(selectedCategory == category ? .black : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedCategory == category ? Color(UIColor.systemGray6) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedCategory == category ? color : Color.gray.opacity(0.2), lineWidth: selectedCategory == category ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func devTeamButton(_ team: FeedbackTeam, title: String, subtitle: String) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            selectedTeam = team
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedTeam == team ? Color.blue : Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: team == .devFrontend ? "iphone" : "server.rack")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedTeam == team ? .white : .blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if selectedTeam == team {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTeam == team ? Color.blue : Color.gray.opacity(0.2), lineWidth: selectedTeam == team ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button(action: submitFeedback) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Submit Feedback")
                }
            }
            .font(.custom("Inter-Bold", size: 16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(canSubmit ? Color.blue : Color.gray)
            )
        }
        .disabled(!canSubmit || isSubmitting)
        .padding(.top, 8)
    }
    
    private var canSubmit: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedTeam != nil
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Feedback Sent!")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
                
                Text("Thank you for your feedback")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1C1C1E"))
            )
        }
        .transition(.opacity)
    }
    
    // MARK: - Submit Action
    
    private func submitFeedback() {
        print("[FeedbackPopup] submitFeedback called")
        print("[FeedbackPopup] canSubmit: \(canSubmit), selectedTeam: \(String(describing: selectedTeam))")
        guard canSubmit, let team = selectedTeam else {
            print("[FeedbackPopup] Guard failed - returning early")
            return
        }
        
        print("[FeedbackPopup] Starting submission for team: \(team.displayName)")
        isSubmitting = true
        errorMessage = nil
        
        // Update feedback data
        feedbackManager.currentFeedback.description = feedbackText
        feedbackManager.currentFeedback.team = team
        
        Task {
            do {
                print("[FeedbackPopup] Calling LinearService...")
                let issue = try await LinearService.shared.createFeedbackIssue(
                    title: generateTitle(),
                    description: feedbackText,
                    team: team,
                    screenshot: feedbackManager.currentFeedback.screenshot
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessMessage = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    print("Created Linear issue: \(issue.identifier) - \(issue.url)")
                    
                    // Dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        feedbackManager.resetFeedback()
                        dismiss()
                    }
                }
            } catch {
                print("[FeedbackPopup] ERROR: \(error)")
                print("[FeedbackPopup] Error description: \(error.localizedDescription)")
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func generateTitle() -> String {
        // Generate a title from the first line or first few words
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
        
        if firstLine.count <= 60 {
            return "[Feedback] \(firstLine)"
        } else {
            let truncated = String(firstLine.prefix(57))
            return "[Feedback] \(truncated)..."
        }
    }
}

#Preview {
    FeedbackPopupView()
}

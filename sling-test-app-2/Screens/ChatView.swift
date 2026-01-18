import SwiftUI
import UIKit

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatService = ChatService()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Close chat")
                
                Spacer()
                
                Text("Sling Assistant")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Spacer()
                
                // Clear chat button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    chatService.clearChat()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Clear chat")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            Divider()
            
            // Messages or Empty State
            if chatService.messages.isEmpty && !chatService.isLoading && !chatService.isStreaming {
                // Empty state
                Spacer()
                
                // Dynamic greeting
                VStack(spacing: 8) {
                    Text(greetingText)
                        .font(.custom("Inter-Bold", size: 28))
                        .tracking(-0.56)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "080808"))
                    
                    Text("Your AI helper to answer any questions")
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Streaming message (word by word)
                            if chatService.isStreaming && !chatService.streamingContent.isEmpty {
                                StreamingBubble(content: chatService.streamingContent)
                                    .id("streaming")
                            }
                            
                            // Loading indicator
                            if chatService.isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: chatService.messages.count) { _, _ in
                        withAnimation {
                            if let lastMessage = chatService.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatService.isLoading) { _, isLoading in
                        if isLoading {
                            withAnimation {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatService.streamingContent) { _, _ in
                        if chatService.isStreaming {
                            withAnimation {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Input area
            HStack(spacing: 12) {
                // Text field container
                HStack(spacing: 8) {
                    TextField("Ask anything", text: $inputText, axis: .vertical)
                        .font(.custom("Inter-Regular", size: 16))
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                    
                    // Microphone button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "mic")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "999999"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "F7F7F7"))
                .cornerRadius(24)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "FF5113"))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Send message")
                .disabled(chatService.isLoading || chatService.isStreaming)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isInputFocused = true
        }
    }
    
    private func sendMessage() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        inputText = ""
        
        Task {
            await chatService.sendMessage(content)
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        
        switch hour {
        case 5..<12:
            timeOfDay = "this morning"
        case 12..<17:
            timeOfDay = "this afternoon"
        case 17..<21:
            timeOfDay = "this evening"
        default:
            timeOfDay = "today"
        }
        
        return "How can I help you \(timeOfDay)?"
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            if isUser {
                // User messages in bubble
                Text(message.content)
                    .font(.custom("Inter-Regular", size: 15))
                    .foregroundColor(Color(hex: "080808"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        ChatBubbleShape(isUser: true)
                            .fill(Color(hex: "F7F7F7"))
                    )
            } else {
                // Assistant messages with markdown support
                Text(parseMarkdown(message.content))
                    .font(.custom("Inter-Regular", size: 15))
                    .foregroundColor(Color(hex: "080808"))
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
    
    // Parse markdown and return AttributedString
    private func parseMarkdown(_ content: String) -> AttributedString {
        do {
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            let attributedString = try AttributedString(markdown: content, options: options)
            return attributedString
        } catch {
            return AttributedString(content)
        }
    }
}

// MARK: - Streaming Text (for word-by-word animation)

struct StreamingBubble: View {
    let content: String
    
    var body: some View {
        HStack {
            Text(parseMarkdown(content))
                .font(.custom("Inter-Regular", size: 15))
                .foregroundColor(Color(hex: "080808"))
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
    }
    
    // Parse markdown and return AttributedString
    private func parseMarkdown(_ content: String) -> AttributedString {
        do {
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            return try AttributedString(markdown: content, options: options)
        } catch {
            return AttributedString(content)
        }
    }
}

// MARK: - Chat Bubble Shape with Tail (iMessage style)

struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        var path = Path()
        
        if isUser {
            // User bubble - tail on bottom right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            
            // Top edge and top-right corner
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            
            // Right edge down to where tail starts
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 6))
            
            // Tail curves: out, down to point, then curves back with hollow
            path.addCurve(
                to: CGPoint(x: rect.maxX + 6, y: rect.maxY + 3),
                control1: CGPoint(x: rect.maxX, y: rect.maxY),
                control2: CGPoint(x: rect.maxX + 6, y: rect.maxY - 2)
            )
            path.addCurve(
                to: CGPoint(x: rect.maxX - 10, y: rect.maxY),
                control1: CGPoint(x: rect.maxX + 2, y: rect.maxY + 4),
                control2: CGPoint(x: rect.maxX - 4, y: rect.maxY)
            )
            
            // Bottom edge
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            
            // Bottom-left corner
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                       radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            
            // Left edge and top-left corner
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            
        } else {
            // Assistant bubble - tail on bottom left
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            
            // Top edge and top-right corner
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            
            // Right edge and bottom-right corner
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                       radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            
            // Bottom edge to tail
            path.addLine(to: CGPoint(x: rect.minX + 10, y: rect.maxY))
            
            // Tail curves: hollow curve to point, then back up
            path.addCurve(
                to: CGPoint(x: rect.minX - 6, y: rect.maxY + 3),
                control1: CGPoint(x: rect.minX + 4, y: rect.maxY),
                control2: CGPoint(x: rect.minX - 2, y: rect.maxY + 4)
            )
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - 6),
                control1: CGPoint(x: rect.minX - 6, y: rect.maxY - 2),
                control2: CGPoint(x: rect.minX, y: rect.maxY)
            )
            
            // Left edge and top-left corner
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "7B7B7B"))
                    .frame(width: 6, height: 6)
                    .opacity(dotCount == index ? 1.0 : 0.4)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}

#Preview {
    ChatView()
}

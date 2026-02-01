import SwiftUI

/// A standardized bottom drawer component matching the app's design system.
/// Features:
/// - 47px corner radius (matches device corners)
/// - 8px horizontal, 8px top, 16px bottom padding from device edges
/// - 32x6px drawer handle
/// - 0.4 opacity dimmed background
/// - Slide up/down animation (0.25s easeInOut)
/// - Tap outside to dismiss
struct BottomDrawer<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    @State private var sheetOffset: CGFloat = 500
    @State private var backgroundOpacity: Double = 0
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background - fades in/out
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissDrawer()
                }
            
            // Drawer content with device-matching corner radius
            VStack(spacing: 0) {
                // Drawer handle
                DrawerHandle()
                
                // User content
                content
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 47))
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .offset(y: sheetOffset)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.25)) {
                sheetOffset = 0
                backgroundOpacity = 0.4
            }
        }
    }
    
    private func dismissDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) {
            sheetOffset = 500
            backgroundOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Drawer Handle

/// Standard drawer handle used across all bottom drawers
struct DrawerHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.black.opacity(0.2))
            .frame(width: 32, height: 6)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }
}

// MARK: - View Modifier

extension View {
    /// Presents a standardized bottom drawer overlay
    func bottomDrawer<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                BottomDrawer(isPresented: isPresented, content: content)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented.wrappedValue)
    }
}

#Preview {
    Color.gray
        .ignoresSafeArea()
        .bottomDrawer(isPresented: .constant(true)) {
            VStack(spacing: 16) {
                Text("Example Drawer")
                    .font(.custom("Inter-Bold", size: 20))
                
                Text("This is the standard drawer style used across the app.")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
}

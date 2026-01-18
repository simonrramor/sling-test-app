import SwiftUI
import Lottie

/// Animated loader that plays a Lottie animation with spinner and checkmark
struct LoaderWithCheckmark: View {
    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        LottieView(animation: .named("loader-complete"))
            .playing(loopMode: .playOnce)
            .animationDidFinish { completed in
                if completed {
                    onComplete?()
                }
            }
            .frame(width: 64, height: 64)
    }
}

#Preview {
    ZStack {
        Circle()
            .fill(Color(hex: "FF5113"))
            .frame(width: 64, height: 64)
        
        LoaderWithCheckmark()
    }
}

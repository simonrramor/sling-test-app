import SwiftUI

// Animatable wrapper for an array of CGFloat values
// Uses nonisolated conformance to work with @MainActor isolated Shape types
struct AnimatableVector: Sendable {
    var values: [CGFloat]
}

// Mark the entire extension as nonisolated to fix Swift 6 concurrency errors
// when used with @MainActor-isolated Shape types
nonisolated extension AnimatableVector: VectorArithmetic {
    static var zero: AnimatableVector {
        AnimatableVector(values: [])
    }
    
    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [CGFloat](repeating: 0, count: count)
        for i in 0..<count {
            let lhsValue = i < lhs.values.count ? lhs.values[i] : 0
            let rhsValue = i < rhs.values.count ? rhs.values[i] : 0
            result[i] = lhsValue + rhsValue
        }
        return AnimatableVector(values: result)
    }
    
    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [CGFloat](repeating: 0, count: count)
        for i in 0..<count {
            let lhsValue = i < lhs.values.count ? lhs.values[i] : 0
            let rhsValue = i < rhs.values.count ? rhs.values[i] : 0
            result[i] = lhsValue - rhsValue
        }
        return AnimatableVector(values: result)
    }
    
    mutating func scale(by rhs: Double) {
        for i in 0..<values.count {
            values[i] *= CGFloat(rhs)
        }
    }
    
    var magnitudeSquared: Double {
        values.reduce(0) { $0 + Double($1 * $1) }
    }
}

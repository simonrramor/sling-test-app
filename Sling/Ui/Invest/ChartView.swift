import SwiftUI
import UIKit

struct ChartView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var selectedPeriod: String
    @Binding var isDragging: Bool
    @Binding var dragProgress: CGFloat
    var externalChartData: [CGFloat]? = nil  // Optional external data
    var disabledPeriods: [String] = []  // Periods that should be disabled
    @State private var lastHapticInterval: Int = -1
    @State private var animatedPoints: [CGFloat] = []
    
    let periods = ["1H", "1D", "1W", "1M", "1Y", "All"]
    
    // Fallback data for each time period
    let fallbackChartData: [String: [CGFloat]] = [
        "1H": [0.5, 0.52, 0.48, 0.55, 0.53, 0.58, 0.54, 0.60, 0.57, 0.62],
        "1D": [0.4, 0.25, 0.55, 0.2, 0.65, 0.35, 0.8, 0.45, 0.7, 0.6],
        "1W": [0.8, 0.6, 0.4, 0.5, 0.25, 0.45, 0.55, 0.4, 0.6, 0.5],
        "1M": [0.15, 0.4, 0.25, 0.7, 0.35, 0.55, 0.3, 0.75, 0.5, 0.85],
        "1Y": [0.1, 0.2, 0.15, 0.35, 0.25, 0.5, 0.4, 0.65, 0.55, 0.8],
        "All": [0.85, 0.65, 0.45, 0.55, 0.3, 0.4, 0.5, 0.6, 0.7, 0.75]
    ]
    
    // Get source chart data - use external if provided, otherwise fallback
    var sourceChartPoints: [CGFloat] {
        if let external = externalChartData, !external.isEmpty {
            return external
        } else {
            return fallbackChartData[selectedPeriod] ?? fallbackChartData["1D"]!
        }
    }
    
    // Use animated points for display
    var chartPoints: [CGFloat] {
        animatedPoints.isEmpty ? sourceChartPoints : animatedPoints
    }
    
    // Normalize points to a standard count for smooth animation between different data sizes
    private func normalizePoints(_ points: [CGFloat], to count: Int = 20) -> [CGFloat] {
        guard points.count > 1 else { return Array(repeating: points.first ?? 0.5, count: count) }
        var result = [CGFloat]()
        for i in 0..<count {
            let progress = CGFloat(i) / CGFloat(count - 1)
            let exactIndex = progress * CGFloat(points.count - 1)
            let lowerIndex = Int(exactIndex)
            let upperIndex = min(lowerIndex + 1, points.count - 1)
            let fraction = exactIndex - CGFloat(lowerIndex)
            let interpolated = points[lowerIndex] + (points[upperIndex] - points[lowerIndex]) * fraction
            result.append(interpolated)
        }
        return result
    }
    
    // Get Y value at a given progress (0-1) along the chart
    func getYValue(at progress: CGFloat, height: CGFloat) -> CGFloat {
        guard !chartPoints.isEmpty else { return height / 2 }
        let count = chartPoints.count
        let exactIndex = progress * CGFloat(count - 1)
        let lowerIndex = Int(exactIndex)
        let upperIndex = min(lowerIndex + 1, count - 1)
        let fraction = exactIndex - CGFloat(lowerIndex)

        let lowerValue = chartPoints[lowerIndex]
        let upperValue = chartPoints[upperIndex]
        let interpolatedValue = lowerValue + (upperValue - lowerValue) * fraction

        return height * (1 - interpolatedValue)
    }
    
    // Get time label based on period and progress
    func getTimeLabel(at progress: CGFloat) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case "1H":
            // Show times within the last hour (e.g., "3:41pm")
            let minutesAgo = Int((1.0 - progress) * 60)
            let time = calendar.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            return formatter.string(from: time).lowercased()
        case "1D":
            // Show times within the last day (e.g., "3:00pm")
            let hoursAgo = Int((1.0 - progress) * 24)
            let time = calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            return formatter.string(from: time).lowercased()
        case "1W":
            // Show days within the last week (e.g., "Mon")
            let daysAgo = Int((1.0 - progress) * 7)
            let time = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: time)
        case "1M":
            // Show dates within the last month (e.g., "Jan 15")
            let daysAgo = Int((1.0 - progress) * 30)
            let time = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: time)
        case "1Y":
            // Show months within the last year (e.g., "Jan")
            let monthsAgo = Int((1.0 - progress) * 12)
            let time = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: time)
        case "All":
            // Show years (e.g., "2024")
            let yearsAgo = Int((1.0 - progress) * 5)
            let time = calendar.date(byAdding: .year, value: -yearsAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: time)
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Chart
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let dotX = width * dragProgress
                let dotY = getYValue(at: dragProgress, height: height)
                
                ZStack {
                    // Grey line (full chart - shown when dragging)
                    if isDragging {
                        AnimatedChartLine(points: animatedPoints.isEmpty ? normalizePoints(sourceChartPoints) : animatedPoints, width: width, height: height)
                            .stroke(Color(hex: "EDEDED"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: animatedPoints)
                    }
                    
                    // Black line (partial or full based on drag)
                    AnimatedChartLine(points: animatedPoints.isEmpty ? normalizePoints(sourceChartPoints) : animatedPoints, width: width, height: height, trimEnd: dragProgress)
                        .stroke(Color(hex: "080808"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: animatedPoints)
                    
                    // Vertical line at drag position with time label
                    if isDragging {
                        // Vertical line
                        Rectangle()
                            .fill(Color(hex: "EDEDED"))
                            .frame(width: 1)
                            .position(x: dotX, y: height / 2)
                        
                        // Time label at top of line
                        Text(getTimeLabel(at: dragProgress))
                            .font(.custom("Inter-Medium", size: 10))
                            .foregroundColor(themeService.textSecondaryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "EDEDED"))
                            )
                            .position(x: dotX, y: -12)
                    }
                    
                    // Dot
                    if isDragging {
                        // Static dot when dragging
                        Circle()
                            .fill(Color(hex: "080808"))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .position(x: dotX, y: dotY)
                    } else {
                        // Pulsing dot at end when not dragging
                        let lastY = height * (1 - (chartPoints.last ?? 0.5))
                        PulsingDot()
                            .position(x: width, y: lastY)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            if !isDragging {
                                generator.impactOccurred()
                                lastHapticInterval = -1
                            }
                            isDragging = true
                            // Calculate progress based on drag position within the geometry
                            let newProgress = min(max(value.location.x / width, 0), 1)
                            
                            // Haptic feedback at appropriate intervals for each time period
                            let intervals: Int
                            switch selectedPeriod {
                            case "1H":
                                intervals = 12 // Every 5 minutes
                            case "1D":
                                intervals = 48 // Every 30 minutes
                            case "1W":
                                intervals = 7 // Every day
                            case "1M":
                                intervals = 30 // Every day
                            case "1Y":
                                intervals = 12 // Every month
                            case "All":
                                intervals = 5 // Every year
                            default:
                                intervals = 10
                            }
                            
                            let currentInterval = Int(newProgress * CGFloat(intervals))
                            if currentInterval != lastHapticInterval {
                                generator.impactOccurred()
                                lastHapticInterval = currentInterval
                            }
                            
                            dragProgress = newProgress
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isDragging = false
                                dragProgress = 1.0
                            }
                            lastHapticInterval = -1
                        }
                )
            }
            .padding(.leading, -20)
            .padding(.trailing, 40)
            .frame(height: 140)
            
            // Time Period Selector
            HStack {
                ForEach(periods, id: \.self) { period in
                    let isDisabled = disabledPeriods.contains(period)
                    
                    Button {
                        if !isDisabled {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period)
                            .font(.custom(selectedPeriod == period ? "Inter-Medium" : "Inter-Regular", size: 14))
                            .foregroundColor(
                                isDisabled ? Color(hex: "CFCFCF") :
                                (selectedPeriod == period ? Color(hex: "080808") : Color(hex: "7B7B7B"))
                            )
                            .frame(height: 20) // Line height 20
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedPeriod == period && !isDisabled ? Color(hex: "E8E8E8") : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .accessibilityLabel("\(period) time period")
                    .accessibilityAddTraits(selectedPeriod == period ? .isSelected : [])
                    
                    if period != periods.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
        .onAppear {
            // Initialize with normalized points
            animatedPoints = normalizePoints(sourceChartPoints)
        }
        .onChange(of: selectedPeriod) { _, _ in
            // Animate to new chart data when period changes
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                animatedPoints = normalizePoints(sourceChartPoints)
            }
        }
        .onChange(of: externalChartData) { _, newValue in
            // Animate when external data changes
            if let data = newValue, !data.isEmpty {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    animatedPoints = normalizePoints(data)
                }
            }
        }
    }
}

struct AnimatedChartLine: Shape {
    var points: [CGFloat]
    var width: CGFloat
    var height: CGFloat
    var trimEnd: CGFloat = 1.0
    
    // Animate both points and trimEnd
    var animatableData: AnimatablePair<AnimatableVector, CGFloat> {
        get { AnimatablePair(AnimatableVector(values: points), trimEnd) }
        set {
            points = newValue.first.values
            trimEnd = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        guard !points.isEmpty else { return Path() }
        
        // Generate all points including interpolated end point
        let cgPoints: [CGPoint] = points.enumerated().map { index, point in
            let x = width * CGFloat(index) / CGFloat(points.count - 1)
            let y = height * (1 - point)
            return CGPoint(x: x, y: y)
        }
        
        // If trimEnd is less than 1, calculate the end point
        let endX = width * trimEnd
        
        var path = Path()
        guard cgPoints.count > 1 else { return path }
        
        let cornerRadius: CGFloat = 6
        
        path.move(to: cgPoints[0])
        
        for i in 1..<cgPoints.count - 1 {
            let prev = cgPoints[i - 1]
            let curr = cgPoints[i]
            let next = cgPoints[i + 1]
            
            // Stop if we've passed the trim point
            if curr.x > endX {
                // Interpolate to find the exact end point
                let t = (endX - prev.x) / (curr.x - prev.x)
                let endY = prev.y + (curr.y - prev.y) * t
                path.addLine(to: CGPoint(x: endX, y: endY))
                return path
            }
            
            let v1 = CGPoint(x: curr.x - prev.x, y: curr.y - prev.y)
            let v2 = CGPoint(x: next.x - curr.x, y: next.y - curr.y)
            
            let len1 = sqrt(v1.x * v1.x + v1.y * v1.y)
            let len2 = sqrt(v2.x * v2.x + v2.y * v2.y)
            
            let radius = min(cornerRadius, len1 / 2, len2 / 2)
            
            let n1 = CGPoint(x: v1.x / len1 * radius, y: v1.y / len1 * radius)
            let n2 = CGPoint(x: v2.x / len2 * radius, y: v2.y / len2 * radius)
            
            let p1 = CGPoint(x: curr.x - n1.x, y: curr.y - n1.y)
            let p2 = CGPoint(x: curr.x + n2.x, y: curr.y + n2.y)
            
            path.addLine(to: p1)
            path.addQuadCurve(to: p2, control: curr)
        }
        
        // Handle last segment
        let lastPoint = cgPoints.last!
        let secondLast = cgPoints[cgPoints.count - 2]
        
        if lastPoint.x > endX && secondLast.x < endX {
            let t = (endX - secondLast.x) / (lastPoint.x - secondLast.x)
            let endY = secondLast.y + (lastPoint.y - secondLast.y) * t
            path.addLine(to: CGPoint(x: endX, y: endY))
        } else if trimEnd >= 1.0 {
            path.addLine(to: lastPoint)
        }
        
        return path
    }
}

struct PulsingDot: View {
    var color: Color = Color(hex: "080808")
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Pulsing outer ring
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .scaleEffect(isPulsing ? 1.0 : 0.5)
                .opacity(isPulsing ? 0 : 1)

            // Solid center dot
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            withAnimation(
                .easeOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ChartView(selectedPeriod: .constant("1D"), isDragging: .constant(false), dragProgress: .constant(1.0))
}

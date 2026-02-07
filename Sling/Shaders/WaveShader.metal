#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Smooth wave distortion effect - creates a flowing, organic wave pattern
[[ stitchable ]] float2 wave(float2 position, float time, float amplitude, float frequency) {
    float2 offset = float2(0.0);
    
    // Create multiple wave layers for organic feel
    offset.x = sin(position.y * frequency * 0.01 + time * 2.0) * amplitude;
    offset.y = cos(position.x * frequency * 0.01 + time * 1.5) * amplitude * 0.5;
    
    // Add secondary wave for more complexity
    offset.x += sin(position.y * frequency * 0.02 - time * 1.2) * amplitude * 0.3;
    offset.y += cos(position.x * frequency * 0.015 + time * 0.8) * amplitude * 0.4;
    
    return position + offset;
}

// Ripple effect emanating from center
[[ stitchable ]] float2 ripple(float2 position, float2 size, float time, float amplitude) {
    float2 center = size / 2.0;
    float2 delta = position - center;
    float distance = length(delta);
    
    // Create ripple waves moving outward
    float wave = sin(distance * 0.05 - time * 4.0) * amplitude;
    wave *= exp(-distance * 0.005); // Fade out with distance
    wave *= smoothstep(0.0, 1.0, time * 0.5); // Fade in
    
    // Apply displacement along the radial direction
    float2 direction = normalize(delta + 0.001);
    return position + direction * wave;
}

// Color shimmer effect - adds an iridescent glow with moving highlight
[[ stitchable ]] half4 shimmer(float2 position, half4 color, float time, float intensity) {
    // Create a moving highlight band that sweeps across the card
    float highlightPos = fmod(time * 80.0, 400.0) - 50.0; // Moves across the card
    float distToHighlight = abs(position.x + position.y * 0.5 - highlightPos);
    float highlight = smoothstep(60.0, 0.0, distToHighlight) * intensity * 0.4;
    
    // Create moving color bands for iridescence
    float shimmerWave = sin(position.x * 0.03 + position.y * 0.02 + time * 4.0);
    shimmerWave = shimmerWave * 0.5 + 0.5;
    
    // Brightness variation
    float brightness = 1.0 + shimmerWave * intensity * 0.12 + highlight;
    
    // Iridescent hue shift - more pronounced
    half3 shifted = color.rgb;
    shifted.r *= 1.0 + sin(time * 3.0 + position.x * 0.015) * intensity * 0.15;
    shifted.g *= 1.0 + sin(time * 2.5 + position.y * 0.012) * intensity * 0.08;
    shifted.b *= 1.0 + cos(time * 3.5 + position.y * 0.015) * intensity * 0.15;
    
    return half4(shifted * brightness, color.a);
}

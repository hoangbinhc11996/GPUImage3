#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

struct MotionBlurUniform {
    float2 directionalTexelStep;
};

fragment half4 motionBlurFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  constant MotionBlurUniform& uniform [[buffer(1)]])
{
    constexpr sampler quadSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 step = uniform.directionalTexelStep;

    // Gaussian-weighted taps along the motion direction for a smoother streak.
    const int sampleCount = 6;
    const float sigma = 3.0;

    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    float weightSum = 1.0;

    for (int i = 1; i <= sampleCount; ++i) {
        float w = exp(-0.5f * (float(i) * float(i)) / (sigma * sigma));
        float2 offset = step * float(i);
        color += inputTexture.sample(quadSampler, fragmentInput.textureCoordinate + offset) * half(w);
        color += inputTexture.sample(quadSampler, fragmentInput.textureCoordinate - offset) * half(w);
        weightSum += 2.0f * w;
    }

    color /= half(weightSum);
    return color;
}

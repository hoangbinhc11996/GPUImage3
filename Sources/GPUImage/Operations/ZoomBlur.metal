#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct {
    float2 center;
    float size;
    float padding; // alignment
} ZoomBlurUniform;


fragment half4 zoomBlurFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                             texture2d<half> inputTexture [[texture(0)]],
                             constant ZoomBlurUniform& uniform [[buffer(1)]])
{
    constexpr sampler quadSampler;
    float2 direction = (uniform.center - fragmentInput.textureCoordinate);
    // Base step grows with distance from center and requested size; 0.5 keeps reach similar to CI.
    float2 baseStep = direction * (uniform.size * 0.5f);

    const int sampleCount = 6;
    const float sigma = 3.0;

    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    float weightSum = 1.0;

    for (int i = 1; i <= sampleCount; ++i) {
        float w = exp(-0.5f * (float(i) * float(i)) / (sigma * sigma));
        float2 offset = baseStep * float(i);
        color += inputTexture.sample(quadSampler, fragmentInput.textureCoordinate + offset) * half(w);
        color += inputTexture.sample(quadSampler, fragmentInput.textureCoordinate - offset) * half(w);
        weightSum += 2.0f * w;
    }

    color /= half(weightSum);
    return color;
}

#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct
{
    float intensity;
} IntensityUniform;

fragment half4 lookup32Fragment(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant IntensityUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler textureSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    half4 base = inputTexture.sample(textureSampler, fragmentInput.textureCoordinate);

    half blueColor = base.b * 31.0h;
    half2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0h);
    quad1.x = floor(blueColor) - (quad1.y * 8.0h);

    half2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0h);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0h);

    float2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/256.0 + ((0.125 - 1.0/256.0) * base.r);
    texPos1.y = (quad1.y * 0.25) + 0.5/128.0 + ((0.25 - 1.0/128.0) * base.g);

    float2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/256.0 + ((0.125 - 1.0/256.0) * base.r);
    texPos2.y = (quad2.y * 0.25) + 0.5/128.0 + ((0.25 - 1.0/128.0) * base.g);

    half4 newColor1 = inputTexture2.sample(textureSampler, texPos1);
    half4 newColor2 = inputTexture2.sample(textureSampler, texPos2);

    half4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return half4(mix(base, half4(newColor.rgb, base.w), half(uniform.intensity)));
}

//
//  Shaders.metal
//  EdgeDetection
//
//  Created by Denys Litvinskyi on 13.01.2023.
//

#include <metal_stdlib>
using namespace metal;

float height(texture2d<float, access::read> inTexture,
             uint2 origin,
             uint2 offset)
{
  uint2 transformed = origin + offset;
  float4 inColor = inTexture.read(transformed);
  return dot(inColor.rgb, float3(0.2126, 0.7152, 0.0722));
}

kernel void prewitt(texture2d<float, access::read> inTexture [[texture(0)]],
                    texture2d<float, access::write> outTexture [[texture(1)]],
                    uint2 gid [[thread_position_in_grid]])
{
  float northLuma =     height(inTexture, gid, uint2(0, -1));
  float northEastLuma = height(inTexture, gid, uint2(1, -1));
  float eastLuma =      height(inTexture, gid, uint2(1, 0));
  float southEastLuma = height(inTexture, gid, uint2(1, 1));
  float southLuma =     height(inTexture, gid, uint2(0, 1));
  float southWestLuma = height(inTexture, gid, uint2(-1, 1));
  float westLuma =      height(inTexture, gid, uint2(-1, 0));
  float northWestLuma = height(inTexture, gid, uint2(-1, -1));

  // --- x ---   --- y ---
  // -1  0  1    -1 -1 -1
  // -1  0  1     0  0  0
  // -1  0  1     1  1  1
  float dX = northWestLuma + westLuma + southWestLuma - northEastLuma - eastLuma - southEastLuma;
  float dY = northWestLuma + northLuma + northEastLuma - southWestLuma - southLuma - southEastLuma;

  // convert normal from [−1,1] to [0,1] by (N+1)/2
  float dXNormalized = (dX + 1.0) * 0.5;
  float dYNormalized = (dY + 1.0) * 0.5;

  // normal map stores x as r, y as g and z as b
  float3 outColor(dXNormalized, dYNormalized, 1.0);
  outTexture.write(float4(outColor, 1.0), gid);

  // apply gamma correction
  float3 gammaCorrectedColor = pow(outColor.rgb, float3(2.2, 2.2, 2.2));

  float alpha = 1.0;
  outTexture.write(float4(gammaCorrectedColor, alpha), gid);
}

kernel void sobel(texture2d<float, access::read> inTexture [[texture(0)]],
                  texture2d<float, access::write> outTexture [[texture(1)]],
                  uint2 gid [[thread_position_in_grid]])
{
  // --- x ---
  // -1  0  1
  // -2  0  2
  // -1  0  1
  float dX = 0.0;
  dX += -1 * height(inTexture, gid, uint2(-1, -1)); // top left
  dX += -2 * height(inTexture, gid, uint2(-1, 0)); // left
  dX += -1 * height(inTexture, gid, uint2(-1, 1)); // bot left
  dX += 1 * height(inTexture, gid, uint2(1, -1)); // top right
  dX += 2 * height(inTexture, gid, uint2(1, 0)); // right
  dX += 1 * height(inTexture, gid, uint2(1, 1)); // bot right

  // --- y ---
  // -1 -2 -1
  //  0  0  0
  //  1  2  1
  float dY = 0.0;
  dY += -1 * height(inTexture, gid, uint2(-1, -1)); // top left
  dY += -2 * height(inTexture, gid, uint2(0, -1)); // top
  dY += -1 * height(inTexture, gid, uint2(1, -1)); // top right
  dY += 1 * height(inTexture, gid, uint2(-1, 1)); // bot left
  dY += 2 * height(inTexture, gid, uint2(0, 1)); // bot
  dY += 1 * height(inTexture, gid, uint2(1, 1)); // bot right

  // convert normal from [−1,1] to [0,1] by (N+1)/2
  float dXNormalized = (dX + 1.0) * 0.5;
  float dYNormalized = (dY + 1.0) * 0.5;

  // normal map stores x as r, y as g and z as b
  float3 outColor(dXNormalized, dYNormalized, 1.0);
  outTexture.write(float4(outColor, 1.0), gid);

  // apply gamma correction
  float3 gammaCorrectedColor = pow(outColor.rgb, float3(2.2, 2.2, 2.2));

  float alpha = 1.0;
  outTexture.write(float4(gammaCorrectedColor, alpha), gid);
}

kernel void sobelz(texture2d<float, access::read> inTexture [[texture(0)]],
                  texture2d<float, access::write> outTexture [[texture(1)]],
                  uint2 gid [[thread_position_in_grid]])
{
  float northLuma =     height(inTexture, gid, uint2(0, -1));
  float northEastLuma = height(inTexture, gid, uint2(1, -1));
  float eastLuma =      height(inTexture, gid, uint2(1, 0));
  float southEastLuma = height(inTexture, gid, uint2(1, 1));
  float southLuma =     height(inTexture, gid, uint2(0, 1));
  float southWestLuma = height(inTexture, gid, uint2(-1, 1));
  float westLuma =      height(inTexture, gid, uint2(-1, 0));
  float northWestLuma = height(inTexture, gid, uint2(-1, -1));

  // --- x ---   --- y ---
  // -1  0  1    -1 -2 -1
  // -2  0  2     0  0  0
  // -1  0  1     1  2  1
  float dX = northWestLuma + 2*westLuma + southWestLuma - northEastLuma - 2*eastLuma - southEastLuma;
  float dY = northWestLuma + 2*northLuma + northEastLuma - southWestLuma - 2*southLuma - southEastLuma;
  float dZ = 1.0 / 8.0;

  // convert normal from [−1,1] to [0,1] by (N+1)/2
  float dXNormalized = (dX + 1.0) * 0.5;
  float dYNormalized = (dY + 1.0) * 0.5;
  float dZNormalized = (dZ + 1.0) * 0.5;

  // normal map stores x as r, y as g and z as b
  float3 outColor(dXNormalized, dYNormalized, dZNormalized);
  outTexture.write(float4(outColor, 1.0), gid);

  // apply gamma correction
  float3 gammaCorrectedColor = pow(outColor.rgb, float3(2.2, 2.2, 2.2));

  float alpha = 1.0;
  outTexture.write(float4(gammaCorrectedColor, alpha), gid);
}

kernel void scharr(texture2d<float, access::read> inTexture [[texture(0)]],
                   texture2d<float, access::write> outTexture [[texture(1)]],
                   uint2 gid [[thread_position_in_grid]])
{
  float northLuma =     height(inTexture, gid, uint2(0, -1));
  float northEastLuma = height(inTexture, gid, uint2(1, -1));
  float eastLuma =      height(inTexture, gid, uint2(1, 0));
  float southEastLuma = height(inTexture, gid, uint2(1, 1));
  float southLuma =     height(inTexture, gid, uint2(0, 1));
  float southWestLuma = height(inTexture, gid, uint2(-1, 1));
  float westLuma =      height(inTexture, gid, uint2(-1, 0));
  float northWestLuma = height(inTexture, gid, uint2(-1, -1));

  // --- x ---    --- y ---
  //  3  0  -3     3  10  3
  // 10  0 -10     0   0  0
  //  3  0  -3    -3 -10  3
  float dX = 3*northWestLuma + 10*westLuma + 3*southWestLuma -3*northEastLuma -10*eastLuma -3*southEastLuma;
  float dY = 3*northWestLuma + 10*northLuma + 3*northEastLuma -3*southWestLuma -10*southLuma -3*southEastLuma;

  // convert normal from [−1,1] to [0,1] by (N+1)/2
  float dXNormalized = (dX + 1.0) * 0.5;
  float dYNormalized = (dY + 1.0) * 0.5;

  float strength = 2.5;
  float level = 7.0;
  float dZ = 1.0 / strength * (1.0 + pow(2.0, level));

  // normal map stores x as r, y as g and z as b
  float3 outColor(dXNormalized, dYNormalized, dZ);
  outTexture.write(float4(outColor, 1.0), gid);

  // apply gamma correction
  float3 gammaCorrectedColor = pow(outColor.rgb, float3(2.2, 2.2, 2.2));

  float alpha = 1.0;
  outTexture.write(float4(gammaCorrectedColor, alpha), gid);
}

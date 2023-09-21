#version 460
#pragma vscode_glsllint_stage : compute

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform image2D frameTarget;
layout(set = 1, binding = 0, std430) restrict readonly buffer RenderData {
    vec2 randomOffset;
};

void rng_pcg4d(inout uvec4 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.w;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v.w += v.y * v.z;
	v = v ^ (v >> 16u);
	v.x += v.y * v.w;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v.w += v.y * v.z;
}

void main() {
    ivec2 frameSize = imageSize(frameTarget);
    ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);

	vec2 offset = frameSize * randomOffset;

    uvec4 seed = uvec4(uint(offset.x), uint(offset.y), uint(pixelCoords.x), uint(pixelCoords.y));
    rng_pcg4d(seed);
    vec3 random = vec3(seed.xyz) / float(0xffffffffu);

    imageStore(frameTarget, pixelCoords, vec4(random, 1.0));
}
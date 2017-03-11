// Exclusive to SSAO for now
#version 450

#ifdef GL_ES
precision mediump float;
#endif

#include "../compiled.glsl"
#include "../std/gbuffer.glsl"
// getNor()

uniform sampler2D tex;
uniform sampler2D gbuffer0;

uniform vec2 dirInv; // texStep

in vec2 texCoord;
out vec4 fragColor;

const float blurWeights[10] = float[] (0.132572, 0.125472, 0.106373, 0.08078, 0.05495, 0.033482, 0.018275, 0.008934, 0.003912, 0.001535);
const float discardThreshold = 0.95;

float doBlur(const float blurWeight, const int pos, const vec3 nor, const vec2 texCoord) {
	const float posadd = pos + 0.5;

	vec3 nor2 = getNor(texture(gbuffer0, texCoord + pos * dirInv).rg);
	float influenceFactor = step(discardThreshold, dot(nor2, nor));
	float col = texture(tex, texCoord + posadd * dirInv).r;
	fragColor.r += col * blurWeight * influenceFactor;
	float weight = blurWeight * influenceFactor;
	
	nor2 = getNor(texture(gbuffer0, texCoord - pos * dirInv).rg);
	influenceFactor = step(discardThreshold, dot(nor2, nor));
	col = texture(tex, texCoord - posadd * dirInv).r;
	fragColor.r += col * blurWeight * influenceFactor;
	weight += blurWeight * influenceFactor;
	
	return weight;
}

void main() {
	vec2 tc = texCoord * ssaoTextureScale;
	vec3 nor = getNor(texture(gbuffer0, texCoord).rg);
	
	fragColor.r = texture(tex, tc).r * blurWeights[0];
	float weight = blurWeights[0];
	// for (int i = 1; i < 10; i++) {
		weight += doBlur(blurWeights[1], 1, nor, tc);
		weight += doBlur(blurWeights[2], 2, nor, tc);
		weight += doBlur(blurWeights[3], 3, nor, tc);
		weight += doBlur(blurWeights[4], 4, nor, tc);
		weight += doBlur(blurWeights[5], 5, nor, tc);
		weight += doBlur(blurWeights[6], 6, nor, tc);
		weight += doBlur(blurWeights[7], 7, nor, tc);
		weight += doBlur(blurWeights[8], 8, nor, tc);
		weight += doBlur(blurWeights[9], 9, nor, tc);
	// }

	fragColor.r /= weight; // SSAO only
}

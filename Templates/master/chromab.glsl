#version 410

#define saturate(x) clamp(x, 0.0, 1.0)

uniform sampler2D uImages[1];
uniform vec2 uResolution;

uniform float uVignette = 1.0;
const float VignetteAspect = 0.0;
const float VignetteRound = 0.0;
const float VignetteRadius = 0.66;
const float VignetteScale = 2.19;
const float VignettePow = 2.0;
const vec3 VignetteColor = vec3(0.0);

const float ChromaticAberration = 1.0;
const int ChromaticAberrationSteps = 50;
uniform float uChromaticAberrationRadius = 0.1;
const float ChromaticAberrationShape = 0.125;

float fBoxRound(vec2 p, vec2 b)
{
    vec2 d = abs(p) - b;
    return length(max(d, 0)) + max(min(d.x, 0), min(d.y, 0));
}

vec3 Vignette(vec2 clipUv, vec3 col)
{
    float ar = mix(1.0, uResolution.y / uResolution.x, VignetteAspect);
    float w = uVignette * mix(
        fBoxRound(clipUv, VignetteRadius * vec2(ar, 1.0)),
        length(clipUv * vec2(ar, 1.0)) - VignetteRadius, VignetteRound) * VignetteScale;
    return mix(col, VignetteColor, pow(clamp(w, 0.0, 1.0), VignettePow));
}

vec3 AberrationColor(float f)
{
    f = f * 3.0 - 1.5;
    return saturate(vec3(-f, 1.0 - abs(f), f));
}

vec3 ChromAb(vec2 uv, vec2 clipUv, vec3 col)
{
    vec3 chroma = vec3(0.0);
    vec3 w = vec3(0.001);
    vec2 dir = clipUv * pow(dot(clipUv, clipUv), ChromaticAberrationShape);

    for(int j = 1; j <= ChromaticAberrationSteps; ++j)
    {
        float t = float(j) / float(ChromaticAberrationSteps);
        float d = t * uChromaticAberrationRadius * 0.125;
        vec3 s = AberrationColor(t);
        w += s;
        chroma.xyz += texture(uImages[0], uv - dir * d).xyz * s;
    }

    return mix(col, chroma / w, ChromaticAberration);
}

out vec4 outColor;

void main()
{
    vec2 uv = gl_FragCoord.xy / uResolution;
    vec2 clipUv = uv * 2.0 - 1.0;
    outColor = texture(uImages[0], uv);
    outColor.xyz = Vignette(clipUv, ChromAb(uv, clipUv, outColor.xyz));
}

float FogRemap(float fog)
{
    return pow(fog, 6.0);
}

vec3 FogColor(Ray ray, float fog)
{
    return mix(vec3(1.0), vec3(0.3, 0.05, 0.5).xzy, smoothstep(-0.2, 0.1, ray.direction.y));
}

// #define uTimer uBeats
uniform float uTimer = 0.0;
uniform vec3 uFlash = vec3(60.0, 50.0, 40.0);
uniform float uRadius = 1.0;
float fEmissive(vec3 p, out vec4 m)
{
    m = vec4(uFlash, -1);
    return length(p - vec3(0.0, 3.0 + sin(uTimer), 0.0)) - uRadius;
}
float fEmissive(vec3 p) { vec4 m; return fEmissive(p, m); }

float fShadowCaster(vec3 p, out vec4 m)
{
    float r = p.y;
    m = vec4(p, 1.0);

    float cell;
    {
        float r = length(p.xz);
        float a = atan(p.x, p.z) / 6.28;
        cell = floor(a * 8.0 + 0.5);
        a = (fract(a * 8.0 + 0.5) - 0.5) / 8.0;
        p.xz = vec2(sin(a * 6.28), cos(a * 6.28)) * r;
        p.z -= 5.5;
    }

    float f = fract(uTimer * 0.5 + cell * 0.125);
    float pr = f * 3.14 * 6.0;
    float s = min(3.0 - abs(3.0 - f * 6.0), 1.0);
    s *= smoothstep(0.25, 0.5, s);
    vec3 anim = vec2(1.25 + s * -cos(pr) * 0.75, 1.25 + s * -cos(pr) * -0.75).xyx;
    anim.xz *= 0.5;
    float a = 0.5 - sin(f * 3.14) * 0.5 * s;
    float b = sin(f * 3.14 * 1.5 - 3.14 * 0.25) * 3.0;
    p.y -= a + max(b, 0.0);

    float ir = vmax(abs(p) - anim);
    if(ir < r)
    {
        r = ir;
        m = vec4(p,1.0);
    }

    return r;
}

float fShadowCaster(vec3 p) { vec4 m; return fShadowCaster(p, m); }

float fField(vec3 p, out vec4 m)
{
    vec4 tmp;
    float ir = fShadowCaster(p, tmp), r = fEmissive(p, m);
    fOpUnion(r, ir, m, tmp);
    return r;
}

/*
vec3 albedo
vec3 additive
float specularity
float roughness
float reflectivity
float blur
float metallicity
*/
Material GetMaterial(Hit hit, Ray ray)
{
    int objectId = int(hit.materialId.w);
    if(objectId==-1) // emissive material
        return Material(vec3(0.0), vec3(hit.materialId.xyz), 0.0, 0.0, 0.0, 0.0, 0.0);
    return Material(vec3(1.0), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz,ShadowArgs(0.1, dE, 64.0, 100))/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);
    // result += DirectionalLight(data, vec3(0.5, 1.0, 1.0), vec3(1.0), shadowArgs());

    // Emissive light
    IMPL_EMISSIVE_LIGHT(result, fEmissive);

    return result;
}

vec3 Normal(Hit hit)
{
    vec3 p = hit.point;
    vec4 taps = vec4(fField(p+e.xyy),fField(p+e.yxy),fField(p+e.yyx),fField(p));
    return normalize(taps.xyz-taps.w);
}

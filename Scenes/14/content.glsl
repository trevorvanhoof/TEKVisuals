float FogRemap(float fog)
{
    return fog;
}

vec3 FogColor(Ray ray, float fog)
{
    return mix(vec3(1.0), vec3(0.2), smoothstep(-0.2, 0.2, ray.direction.y));
}

float fEmissive(vec3 p, out vec4 m, float pad, float cell)
{
    p.y -= 2.0;
    m = vec4(hsv2rgb(h1(vec4(cell * TAU, sign(p) * 0.1)), 1.0, 1.0), -1);
    p = abs(p) - 1.0;
    p.z -= pad;
    float r = fBoxRound(p, vec3(0.5, 0.5, 0.0)) - 0.1;
    return r;
}

const float tunnelDepth = 4.0;
const float modDist = tunnelDepth + tunnelDepth + tunnelDepth + 2.0;

float fEmissive1(vec3 p, out vec4 m)
{
    float cell = pMod(p.z, modDist);
    float r = fEmissive(p, m, tunnelDepth, cell);
    m.xyz *= max(0.0, abs(fract(uBeats * 0.5 + 0.5 + cell * 0.5) - 0.5) * 4.0 - 1.0);
    return r;
}
float fEmissive2(vec3 p, out vec4 m)
{
    float cell = pMod(p.z, modDist);
    float r = fEmissive(p.zyx, m, 2.0, cell);
    m.xyz *= max(0.0, abs(fract(uBeats * 0.5 + cell * 0.5) - 0.5) * 4.0 - 1.0);
    return r;
}
float fEmissive1(vec3 p)
{ vec4 m; return fEmissive1(p, m); }
float fEmissive2(vec3 p)
{ vec4 m; return fEmissive2(p, m); }

uniform float uTwirl = 0.0;
uniform float uBend = 0.0;
float fField(vec3 p, out vec4 m)
{
    p.z -= uV[3].z;
    pR(p.xz, p.z * uBend);
    p.z += uV[3].z;

    p.y -= 2.0;
    pR(p.xy, p.z * TAU / modDist * uTwirl);
    p.y += 2.0;

    vec4 im;
    float r = fEmissive1(p, m), ir = fEmissive2(p, im);
    fOpUnion(r, ir, m, im);

    p.y -= 2.0;
    pMod(p.z, modDist);
    p = abs(p);
    p.x = min(p.x, p.z);
    ir = -vmax(p.xy - 2.0);
    fOpUnion(r,ir,m,vec4(p,1));

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
    // if(objectId==2)
    {
        vec2 uv = projectTri(hit.point, hit.normal);
        vec4 tex = texture(uImages[3], uv * 0.025);
        float refl = quad(smoothstep(1.5, 0.0, tex.x + tex.z + tex.w * 0.1));
        return Material(vec3(0.125), vec3(0.0), refl, 1.0, refl, 0.3, 0.0);
    }
    return Material(vec3(1.0), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);
    // result += DirectionalLight(data, vec3(0.5, 1.0, 1.0), vec3(1.0), shadowArgs());

    // Emissive light
    IMPL_EMISSIVE_LIGHT(result, fEmissive1);
    IMPL_EMISSIVE_LIGHT(result, fEmissive2);

    return result;
}

vec3 Normal(Hit hit)
{
    vec3 p = hit.point;
    vec4 taps = vec4(fField(p+e.xyy),fField(p+e.yxy),fField(p+e.yyx),fField(p));
    return normalize(taps.xyz-taps.w);
}

float FogRemap(float fog)
{
    return fog;
}

vec3 FogColor(Ray ray, float fog)
{
    return vec3(0.1, 0.2, 0.1);
}

uniform float uEmissiveGrow = 0.0;

float fEmissive(vec3 p, out vec4 m)
{
    float cell = pMod(p.z, 40.0) * 0.05;
    m = vec4(2.0, 50.0, 10.0, -1);
    float b = fTorus(p, 0.01, 10.0);

    cell = pMod(p.z, 10.0) * 0.05;
    vec4 im = vec4(50.0, 10.0, 2.0, -1);
    float a = fTorus(p, 0.01, 1.5);
    fOpUnion(b, a, m, im);

    m.xyz *= (1.0 + uEmissiveGrow * 10.0);
    return b - uEmissiveGrow;
}
float fEmissive(vec3 p) { vec4 m; return fEmissive(p, m); }

float fField(vec3 p, out vec4 m)
{
    p.z -= uV[3].z;
    pR(p.xz, sin(p.z / 40.0) * 0.1);
    p.z += uV[3].z;

    vec4 tmp;
    float ir, r = fEmissive(p, m);

    vec3 op = p;
    ir = abs(2.0 - length(p.xy)) - 0.1;
    pR(p.xz, radians(-45));
    pMod(p.z, 2.0);
    ir = max(ir, abs(p.z) - 0.1);
    fOpUnion(r,ir,m,vec4(p,1));

    p = op;
    float radius = length(p.xy) - 2.5;
    pMod(radius, 8.0);
    ir = abs(radius) - 0.1;
    pR(p.xz, radians(45));
    pMod(p.z, 2.0);
    ir = max(ir, abs(p.z) - 0.1);
    fOpUnion(r,ir,m,vec4(p,1));

    /*p = op;
    pMod(p, 40.0);
    p = abs(p);
    ir = vmax(min(p, p.yzx)) - 0.1;
    ir = max(ir, 0.5 - r);
    fOpUnion(r,ir,m,vec4(p,1));*/

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
    return Material(vec3(0.5), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);
    // result += DirectionalLight(data, vec3(0.5, 1.0, 1.0), vec3(1.0));

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

float FogRemap(float fog)
{
    return fog;
}

vec3 FogColor(Ray ray, float fog)
{
    return mix(vec3(1.0), vec3(0.2), smoothstep(-0.2, 0.2, ray.direction.y));
}

float fEmissive(vec3 p, out vec4 m)
{
    m = vec4(0, 0, 0, -1);
    return FAR;
}
float fEmissive(vec3 p) { vec4 m; return fEmissive(p, m); }

float fField(vec3 p, out vec4 m)
{
    vec4 im;
    vec3 op=p;
    float ir, r = fEmissive(p, m);

    ir = length(p - vec3(0.0, 0.0, 10.0)) - 0.5;
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
    return Material(vec3(0.5), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);
    result += DirectionalLight(data, vec3(0.5, 1.0, 1.0), vec3(1.0), shadowArgs());

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

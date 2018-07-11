float FogRemap(float fog)
{
    return quad(fog);
}

vec3 FogColor(Ray ray, float fog)
{
    return mix(vec3(4.0, 1.0, 4.0), vec3(0.0, 0.5, 2.0), pow(abs(ray.direction.y * 4.0), 0.1));
}

uniform vec4 uLuminanceWave; // distance from camera, falloff distance, luminance (negative means wave will turn lights OFF)
uniform float uTumble;
float fEmissiveTriangles(vec3 p, float offset, out float luminance)
{
    luminance = abs(uLuminanceWave.z);
    if(uLuminanceWave.y > 0.0)
    {
        float fade = sat(abs(p.z - uV[3].z + uLuminanceWave.x) / uLuminanceWave.y);
        if(uLuminanceWave.z > 0.0)
            fade = 1.0 - fade;
        fade = pow(fade, uLuminanceWave.w);
        luminance *= fade;
    }

    p.z -= uV[3].z + 5.0;
    pR(p.xz, sin(p.z * 0.1) * 0.05);
    p.z += uV[3].z + 5.0;

    p.z -= 5.0 * offset;
    float cell = mod(pMod(p.z, 10.0) * 2.0 + offset, 10.0);
    float rand = h1(cell);

    luminance *= 0.1 + 0.9 * (sin((rand - uBeats / 2.0) * TAU) * 0.5 + 0.5);

    pR(p.xy, uTumble * TAU + rand);
    return length(vec2(fWireTriangle(-p.xy, 2.0), p.z)) - 0.001;
}

float fEmissive01(vec3 p, out vec4 m)
{
    float luminance;
    float r = fEmissiveTriangles(p, 0.0, luminance);
    m = vec4(vec3(0.2, 0.5, 1.0) * luminance, -1);
    return r;
}
float fEmissive01(vec3 p){vec4 m;return fEmissive01(p,m);}

float fEmissive02(vec3 p, out vec4 m)
{
    float luminance;
    float r = fEmissiveTriangles(p, 1.0, luminance);
    m = vec4(vec3(1.0, 0.2, 0.5) * luminance, -1);
    return r;
}
float fEmissive02(vec3 p){vec4 m;return fEmissive02(p,m);}

// triangle wave for lo-poly look
float tri(float x)
{
    return abs(fract(x)-0.5);
}

float fField(vec3 p, out vec4 m)
{
    vec4 tmp;
    float r = fEmissive01(p, m),
    ir = fEmissive02(p, tmp);
    fOpUnion(r,ir,m,tmp);

    p.z -= uV[3].z + 5.0;
    pR(p.xz, sin(p.z * 0.1) * 0.05);
    p.z += uV[3].z + 5.0;

    float offset = 0.0;
    float w = 1.0;
    vec3 op = p;
    p.z=mod(p.z,50.0);
    float fade = sat(p.z) * sat(50.0 - p.z);
    for(int i = 0; i < 3; ++i)
    {
        offset += tri(p.x*0.125+tri(p.z*0.125+tri(p.y*0.125))) * w;
        p.xz *= 2.0;
        w *= 0.5;
    }
    offset *= sqrt(fade);
    offset = 3.0 * sqr(offset);

    p=op;
    pR(p.xy, p.z / 50.0 * TAU);
    ir = 6.0 - dot(abs(p.xy),vec2(1))  - offset;
    fOpUnion(r,ir*0.5,m,vec4(0));

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

    return Material(vec3(2.0) * sat(hit.normal.y), vec3(0.0), 0.1, 0.3, 0.1, 2.0, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);

    IMPL_EMISSIVE_LIGHT(result, fEmissive01);
    IMPL_EMISSIVE_LIGHT(result, fEmissive02);

    return result;
}

vec3 Normal(Hit hit)
{
    vec3 p = hit.point;
    vec4 taps = vec4(fField(p+e.xyy),fField(p+e.yxy),fField(p+e.yyx),fField(p));
    return normalize(taps.xyz-taps.w);
}

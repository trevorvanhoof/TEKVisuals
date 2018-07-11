float FogRemap(float fog)
{
    return fog;
}

vec3 FogColor(Ray ray, float fog)
{
    return vec3(0.3, 0.8, 1.0);
}

float fEmissive(vec3 p, out vec4 m)
{
    p.xz = abs(p.xz);
    p.xz -= 30.0;

    p.xz = abs(p.xz);
    p.z -= 1.0;
    p.x -= 4.0;
    p.x = abs(p.x);
    p.x -= 4.0;
    m = vec4(10, 10, 10, -1);
    return fBoxRound(p, vec3(1.0, 0.01, 0.1));
}
float fEmissive(vec3 p) { vec4 m; return fEmissive(p, m); }
uniform float uBoatAppear;
uniform float uBoatAppearRadius;
uniform float uBoatBrightness;
float fField(vec3 p, out vec4 m)
{
    vec4 im;
    vec3 op=p;
    float ir, r = fEmissive(p, m);

    p.xz = abs(p.xz);
    p.xz -= 30.0;
    ir = -fBoxChamfer(p, vec3(20.0, 8.0, 10.0));
    float f = fBox(p - vec3(0.0, 8.0, 0.0), vec3(10.0, 8.0, 0.5));

    p.y += 5.0;
    p.z += 10.0;
    ir = max(-fBoxChamfer(p, vec3(8.0, 2.0, 20.0)), ir);
    ir = max(-fBoxChamfer(p, vec3(30.0, 2.0, 4.0)), ir);
    ir += 0.25;
    fOpUnion(r,ir,m,vec4(p,14));

    fOpUnion(r,f,m,vec4(p,12));

    p.y += 2.6;
    ir = fGreeble(p, 0.3);
    fOpUnion(r,ir,m,vec4(p,13));

    p=op;
    pMod(p.xz, vec2(4.0, 30.0));
    p.z = max(0.0, abs(p.z) - 10.0);
    ir=fTorus(p.yzx, 0.2, 1.0);
    fOpUnion(r,ir,m,vec4(p,12));

    // boat!
    p=op-vec3(30,-5.5,-29.3);
    const float boatScale=2.0;
    p*=boatScale;
    ir=fBoat(p,im)/boatScale;
    float cutoff = fGreeble((p+vec3(0,uBoatAppear,100))*1.5,5.0*1.5)/1.5;
    ir=max(cutoff,ir);
    fOpUnion(r,ir,m,im);
    // laser glow
    ir=length(vec2(cutoff,ir))-uBoatAppearRadius*0.01;
    fOpUnion(r,ir,m,vec4(vec3(40,10,5)*uBoatBrightness,-1));

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
uniform float uLogoFlash;
Material GetMaterial(Hit hit, Ray ray)
{
    int objectId = int(hit.materialId.w);
    if(objectId==-1) // emissive material
        return Material(vec3(0.0), vec3(hit.materialId.xyz), 0.0, 0.0, 0.0, 0.0, 0.0);
    if(objectId<=6)
        return MtlBoat(hit);
    if(objectId==12)
        return Material(vec3(0.01), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
    if(objectId==13)
    {
        vec3 add = vec3(2.0, 0.5, 0.1) * step(0.0, -7.55 - hit.point.y) * quad(h1(floor(hit.point.xz * 4.0)));
        return Material(vec3(0.5), add, 0.1, 0.05, 0.2, 0.0, 0.0);
    }

    vec2 uv = (hit.point.xy + vec2(-2.0, 6.0)) * vec2(-0.5, 0.5);
    uv.x += quad(h1(floor(uv.y * 4.0 + uBeats))) * 0.5 - 0.25;
    vec3 logo = vec3(0.0, 4.0, 3.0) * fLetters(uv) * uLogoFlash;

    return Material(vec3(1.0), logo, 0.1, 0.3, 0.2, 0.3, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);

    // Emissive light
    IMPL_EMISSIVE_LIGHT(result, fEmissive);
    result *= 5.0;

    result += PointLight(data, vec3(-30.0, 0.0, -30.0), vec3(1.0, 0.3, 0.05), 10.0);
    result += PointLight(data, vec3(-30.0, 0.0,  30.0), vec3(1.0, 0.3, 0.05), 10.0);
    result += PointLight(data, vec3( 30.0, 0.0, -30.0), vec3(1.0, 0.3, 0.05), 10.0);
    result += PointLight(data, vec3( 30.0, 0.0,  30.0), vec3(1.0, 0.3, 0.05), 10.0);

    return result;
}

vec3 Normal(Hit hit)
{
    vec3 p = hit.point;
    vec4 taps = vec4(fField(p+e.xyy),fField(p+e.yxy),fField(p+e.yyx),fField(p));
    return normalize(taps.xyz-taps.w);
}

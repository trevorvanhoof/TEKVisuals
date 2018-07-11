float FogRemap(float fog)
{
    return fog;
}

vec3 FogColor(Ray ray, float fog)
{
    return mix(vec3(2.0, 2.0, 0.0) * 0.25, vec3(0.1, 0.4, 0.6), smoothstep(-0.4, 0.2, ray.direction.y));
}

// change the scene into party hard mode
uniform float uMode = 0.0;

vec3 BoatPos(){if(uMode!=0.0)return vec3(0.0);return vec3(48.0, 2.0, 28.0);}
float fEmissive(vec3 p, out vec4 m)
{
    m = vec4(400, 200, 100, -1);
    float r = FAR;
    if(uMode==0.0)
    {
        r = length(p - vec3(400., 30., 0)) - 20.0;
        p-=BoatPos();
        p.z += 1.5;
        pModInterval(p.y, 1.0, 2, 10);
        float ir = fTorus(p.xzy, 0.01, 0.2);
        fOpUnion(r,ir,m,vec4(1,2,3,-1));
    }
    else
    {
        p -= vec3(uV[3].x + 250.0,5.0,0);
        r = fCapsule(p.yxz, 0.05, 10.0);
    }
    return r;
}
float fEmissive(vec3 p) { vec4 m; return fEmissive(p, m); }
uniform float uTunnelNoise = 0.0;
float fField(vec3 p, out vec4 m)
{
    if(uMode!=0.0)
    {
        pR(p.xz,snoise((p.x-uV[3].x)*0.03)*0.01*uTunnelNoise);
        float inside = sign(length(p.yz) - 20.0);
        pR(p.yz, inside * uBeats * TAU * 0.125 * 0.25);
        pModPolarMirror(p.yz, 8.0);
        p.y = 10.0 - abs(20.0 - p.y);
    }

    vec4 im;
    vec3 op=p;
    float ir, r = fEmissive(p, m);

    float animateWater = (uMode==0.0)?1.0:0.0;
    vec2 a = texture(uImages[4], p.y * 0.005 + p.xz * 0.0125 + 0.03 * vec2(0.1, 0.05) * uBeats * animateWater).xz * 0.6;
    vec2 b = texture(uImages[4], p.y * 0.005 + p.xz * 0.025 + 0.08 * vec2(0.05, 0.1) * uBeats * animateWater).yz * 0.3;
    ir = p.y - sqr((a.x + b.x)) * 3.0 - sqr((a.y + b.y) * 1.5) * 3.0;
    fOpUnion(r,ir,m,vec4(p,0));

    float scale = 1.0;
    if(uMode!=0.0)
    {
        p.y -= 5.0;
        pModPolarMirror(p.yz, 8.0);
        pMod(p.x, 100.0);

        p.xz = p.zx;
        p.y -= 1.5;
        scale = 3.0;
    }
    fOpUnion(r,fBoat((p-BoatPos())*scale,im)/scale,m,im);

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
    if(objectId==0) // water
    {
        vec3 alb = vec3(0.3, 0.7, 0.8);
        vec3 add = vec3(0.0);
        alb = mix(alb, vec3(1.5), smoothstep(0.8, 1.4, hit.point.y));
        float fr = quad(sat(1.0 + dot(hit.normal, ray.direction)));
        return Material(alb, add, 0.5, 0.3, fr * 0.1 + 0.1, 0.2, 0.5);
    }
    return MtlBoat(hit);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);
    // Sun
    result += DirectionalLight(data, vec3(1.0, 0.125, 0.0), vec3(4.0, 2.0, 1.0) * 0.125, shadowArgs());

    // Sky
    result += DirectionalLight(data, vec3(-1.0, -0.5, 0.0), vec3(0.1, 0.3, 0.4) * 0.25);

    // Emissive light
    IMPL_EMISSIVE_LIGHT(result, fEmissive);

    if(data.hit.materialId.w==0) // water has additional rim light
        result += RimLight(data, vec3(0.3, 1.2, 1.5) * 0.5, 3.0);

    return result;
}

vec3 Normal(Hit hit)
{
    vec3 p = hit.point;
    vec4 taps = vec4(fField(p+e.xyy),fField(p+e.yxy),fField(p+e.yyx),fField(p));
    return normalize(taps.xyz-taps.w);
}

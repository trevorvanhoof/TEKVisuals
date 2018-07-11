float FogRemap(float fog)
{
    return quad(fog);
}
uniform float uBG = 0.0;
uniform float uShape = 0.0;
uniform float uPT = 0.0;
uniform float uDivs = 6.0;
uniform float uR = 0.5;
uniform float uFlashSpeed = 1.0;

vec3 FogColor(Ray ray, float fog)
{
    vec3 cl = vec3(0);
    cl += uBG * vec3(5,3,1) * pow(1.0 - abs(ray.direction.y), 10.0);
    return cl;
}

float fEmissive(vec3 p, out vec4 m)
{
    m = vec4(0, 0, 0, -1);

    vec3 op = p;
    float cell = floor(p.z / 12.0 + 0.5);
    float luma = 0.001 + quad(fract(uBeats * uFlashSpeed + cell * 0.25));
    m.xyz = hsv2rgb(h1(cell), 0.9, luma * 20.0);
    pR(p.xy, PI * mod(cell, 4.0) * uR);
    pMod(p.z, 12.0);

    float r = fBoxRound(p + vec3(10.0, 0.0, 0.0), vec3(0.05, 8.0, 4.0));
    return r;
}
float fEmissive(vec3 p) { vec4 m; return fEmissive(p, m); }

float fField(vec3 p, out vec4 m)
{
    vec4 im;
    vec3 op=p;

    float ir, r = fEmissive(p, m);
    pR(p.xy, uBeats * 0.25);

    float cell = pMod(p.z, 4.0);
    vec4 rand = h4(cell);
    p.xy += rand.zw * 6.0 - 3.0;
    pR(p.xy, rand.x *TAU);
    float bounds = 2.2 - abs(p.z);
    float x = abs(p.z) - 1.0;
    vec3 p1 = p;
    pR(p1.xy, TAU / uDivs * 0.5);
    pModPolar(p1.xy, uDivs);
    float y = p1.x - 0.41 * (3.0 + rand.y * 15.0);
    y = abs(y) - 0.1;
    if(uShape==0.0)
        ir = max(x, y);
    else
        ir = length(vec2(x, y));
    float bounds2 = length(p.xy) - 15.0 - 3.0 - 3.0;
    ir = max(bounds2, min(ir, bounds));
    fOpUnion(r,ir,m,vec4(p,1));
    if(uShape == 1.0)
        return r;

    r = max(r, 0.5 + 0.5 * h1(p) - length(op - uV[3].xyz));

    vec3 c = floor(op / 10.0 + 0.5);
     pR(op.xy, snoise(op.z * 0.01) * PI);
    op += vec3(0.25, 0.25, 16) * uBeats;
    float cellSize = 9.0;
    const float lineLength = 1.5;
    pMod(op, cellSize);
    cellSize -= lineLength;
    op += (h3(c) * cellSize - cellSize * 0.5);
    ir = fCapsule(op.xzy, 0.0, h1(c) * lineLength);
    fOpUnion(r, ir, m, vec4(hsv2rgb(h1(c), 0.5, 0.5), -1));

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
    return Material(vec3(0.3, 0.6, 0.4), vec3(0.0), 0.1, 0.3, 0.0, 0.0, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);
    // result += DirectionalLight(data, vec3(0.5, 1.0, 1.0), vec3(1.0), shadowArgs());

    // Emissive light
    IMPL_EMISSIVE_LIGHT(result, fEmissive);
    result *= 100.0;

    result += uPT * PointLight(data, vec3(sin(uBeats * TAU * 0.5) * 16.0, 0.0, uV[3].z + 30.0), vec3(8.0, 4.0, 8.0), 4.0);

    return result;
}

vec3 Normal(Hit hit)
{
    vec3 p = hit.point;
    vec4 taps = vec4(fField(p+e.xyy),fField(p+e.yxy),fField(p+e.yyx),fField(p));
    return normalize(taps.xyz-taps.w);
}

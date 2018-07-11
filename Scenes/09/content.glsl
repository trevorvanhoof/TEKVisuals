float FogRemap(float fog)
{
    return sqr(fog);
}

vec3 FogColor(Ray ray, float fog)
{
    return mix(vec3(0.05, 0.1, 0.2) * 2.0, vec3(0.0), pow(abs(ray.direction.y), 0.05));
}
uniform float uEmissiveAmount;
float fEmissive(vec3 p, out vec4 m)
{
    p.z += uBeats * 128.0;
    m = vec4(0, 0, 0, -1);
    vec4 c = vec4(pModPolar(p.xy, 10.0));
    p.x += 2.0;
    c.x = pMod(p.x, 12.0);
    c.z = pMod(p.z, 100.0);
    vec4 rand = h4(c * PI);
    p.z += rand.x * 50.0 - 25.0;
    m.xyz=hsv2rgb(rand.z,0.9,uEmissiveAmount*100.0);
    return fCapsule(p.yzx, 0.01, 10.0 * rand.y);
}
float fEmissive(vec3 p) { vec4 m; return fEmissive(p, m); }


const float gameBoyButtonPopOut = 0.15;
const vec3 gameBoySizeInCm = vec3(9.0, 14.8, 3.2);
const float gameBoyHalfThickness = gameBoySizeInCm.z / 2.0;
void fABButton(inout float r, inout vec4 m, vec3 p)
{
    const float gameBoyButtonBevel = 0.02;
    const float gameBoyButtonSize = 0.55;

    // cylinder for the button
    float a = length(p.xy) - gameBoyButtonSize;
    // sphere for the cap
    float b = length(p + vec3(0.0, 0.0, 0.25)) - 0.25 - gameBoyHalfThickness - gameBoyButtonPopOut;
    // cut off at the back
    float ir = max(-p.z, fOpIntersectionRound(a, b, gameBoyButtonBevel));
    // create inset
    r = fOpIntersectionRound(r, -ir + 0.03, 0.03);
    // intersect round for the final shape
    fOpUnion(r, ir, m, vec4(p, 3));
}

float fGameboy(vec3 p, out vec4 m)
{
    p.y -= 0.34;

    vec2 quadrant = sign(p.xy);
    const float cornerRadius = 0.2;
    // one corner is rounder
    float offset = cornerRadius;
    if(quadrant.x == -1.0 && quadrant.y == -1.0)
        offset = 1.7;

    // body
    float r = fOpIntersectionRound(abs(p.z) - gameBoyHalfThickness, fBoxRound(p.xy, gameBoySizeInCm.xy / 2.0 - offset) - offset, cornerRadius);
    m = vec4(p, 0);

    // top groove
    const vec2 grooveInCm = vec2(0.03, 0.06);
    const float topGrooveOffset = 6.65;
    r = fOpGroove(r, min(p.y - topGrooveOffset, max(-p.y + topGrooveOffset, abs(p.x) - 3.8)), grooveInCm.x, grooveInCm.y);

    // speaker grooves
    vec3 cpy = p;
    cpy.z -= gameBoyHalfThickness;
    cpy.y += 5.8;
    cpy.x += 2.85;
    pR(cpy.xy, radians(-29));
    pModInterval(cpy.x, 0.5, -2, 3);
    float insetDepth = 0.08;
    r = max(r, -max(gameBoyHalfThickness - p.z - insetDepth, fBoxRound(cpy.xy, vec3(0.0, 0.7, 0.0).xy) - 0.15));

    // window inset
    const vec2 insetSize = vec2(7.7, 5.7);
    const vec2 screenSize = vec2(4.7, 4.3);
    p.y -= 3.3;
    quadrant = sign(p.xy);
    offset = 0.3;
    if(quadrant.x == -1.0 && quadrant.y == -1.0)
        offset = 1.0;
    insetDepth = 0.02;
    float ir = max(-p.z + gameBoyHalfThickness - insetDepth, fBoxRound(p.xy, insetSize / 2.0 - offset) - offset);
    fOpIntersection(r, -ir, m, vec4(p, 1));

    // screen inset
    insetDepth = 0.05;
    ir = max(-p.z + gameBoyHalfThickness - insetDepth, fBox(p.xy, screenSize / 2.0));
    if(r <= -ir)
        m = vec4(p, 2);
    r = fOpIntersectionRound(r,-ir,insetDepth);

    // battery
    ir = fSphere(p - vec3(3.3, 0.7, gameBoyHalfThickness), 0.1);
    fOpUnion(r, ir, m, vec4(2.0, 0.1, 0.1, -1));

    // indent AB
    p.xy += vec2(3.3, 5.5);
    float radius = 3.5;
    ir = fCapsule(p, vec3(0.0, 0.0, gameBoyHalfThickness + radius),
                     vec3(1.55, -0.7, gameBoyHalfThickness + radius),
                      radius + 0.1);
    r = max(r, -ir);
    // A & B buttons
    fABButton(r, m, p);
    p.xy += vec2(-1.55, 0.7);
    fABButton(r, m, p);

    // indent D-Pad
    p.xy -= vec2(4.43, 0.25);
    radius = 8.0;
    ir = fSphere(p - vec3(0.0, 0.0, gameBoyHalfThickness + radius), radius + 0.1);
    r = max(r, -ir);

    // D-pad
    const float buttonBevel = 0.06;
    const float crossThickness = 0.28;
    const float crossSize = 1.0;
    const float curveRadius = 18.0;
    const float dimpleCurveRadius = 0.2;

    // create an infinite cross
    vec2 q = abs(p.xy);
    ir = max(-p.z, max(vmax(q) - crossSize, vmin(q) - crossThickness));
    // dimple
    ir = max(ir, 0.04 + dimpleCurveRadius - length(p - vec3(0.0, 0.0, gameBoyHalfThickness + gameBoyButtonPopOut + dimpleCurveRadius)));
    // cut off the front with a curve
    cpy = p;
    cpy.z -= curveRadius + gameBoyHalfThickness + gameBoyButtonPopOut;
    cpy.z = min(cpy.z, 0.0);
    ir = fOpIntersectionRound(curveRadius - length(cpy), ir, buttonBevel);

    fOpUnion(r, ir, m, vec4(p, 4));

    // indent start and select
    ir = fCapsule(p.xy, vec3(-1.05, -2.4, gameBoyHalfThickness).xy, vec3(-1.75, -2.05, gameBoyHalfThickness).xy, -0.05);
    ir = min(ir, fCapsule(p.xy + vec2(1.55, 0.0), vec3(-1.05, -2.4, gameBoyHalfThickness).xy, vec3(-1.75, -2.05, gameBoyHalfThickness).xy, -0.05));
    float squishy = 3.0;
    r = fOpIntersectionChamfer(r * squishy, -ir, 0.37) / squishy;

    // select
    ir = fCapsule(p, vec3(-1.05, -2.4, gameBoyHalfThickness), vec3(-1.75, -2.05, gameBoyHalfThickness), 0.15);
    fOpUnion(r, ir, m, vec4(p, 5));
    // start
    p.x += 1.55;
    ir = fCapsule(p, vec3(-1.05, -2.4, gameBoyHalfThickness), vec3(-1.75, -2.05, gameBoyHalfThickness), 0.15);
    fOpUnion(r, ir, m, vec4(p, 5));

    return r;
}

// triangle wave for lo-poly look
float tri(float x)
{
    return abs(fract(x)-0.5);
}
//float lnoise(float v){float f=floor(v);v-=f;return mix(h1(f),h1(f+1),v);}
//float lnoise(vec2 v){vec2 f=floor(v);v-=f;return mix(mix(h1(f),h1(f+vec2(1,0)),v.x),mix(h1(f+vec2(0,1)),h1(f+1),v.x),v.y);}
//float lnoise(vec3 v){vec3 f=floor(v);v-=f;return mix(mix(mix(h1(f),h1(f+vec3(1,0,0)),v.x),mix(h1(f+vec3(0,1,0)),h1(f+vec3(1,1,0)),v.x),v.y),mix(mix(h1(f+vec3(0,0,1)),h1(f+vec3(1,0,1)),v.x),mix(h1(f+vec3(0,1,1)),h1(f+1),v.x),v.y),v.z);}
float lnoise(vec3 v)
{
    vec3 f = floor(v);
    v -= f;
    f = mix(vec3(h1(f.x), h1(f.y), h1(f.z)), vec3(h1(f.x+1), h1(f.y+1), h1(f.z+1)), v);
    return f.x+f.y+f.z;
}

float fField(vec3 p, out vec4 m)
{
    float r = fGameboy(p, m);

    pR(p.xy, snoise(p.z * 0.01));

    vec4 im;
    float ir = fEmissive(p, im);
    fOpUnion(r, ir, m, im);

    ir = -fHexagon(p.xy, 30.0) + lnoise(p * 0.1) * 10.0 + lnoise(p * 0.2 + uBeats) * 4.0;
    fOpUnion(r, ir, m, vec4(p,6));
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
uniform float uVisorMode = 0.0;
uniform float uVisorNoise = 0.0;
uniform float uInverse = 0.0;
uniform float uBallsAnim = 0.0;
Material GetMaterial(Hit hit, Ray ray)
{
    int objectId = int(hit.materialId.w);
    if(objectId==-1) // emissive material
        return Material(vec3(0.0), vec3(hit.materialId.xyz), 0.0, 0.0, 0.0, 0.0, 0.0);
    if(objectId==0) // body
        return Material(vec3(0.6, 0.55, 0.5), vec3(0.0), 0.1, 0.3, 0.0, 0.0, 0.0);
    if(objectId==1) // gray plate
        return Material(vec3(0.2), vec3(0.0), 0.3, 0.02, 0.0, 0.0, 0.0);
    if(objectId==2) // screen
    {
        vec2 localUv = vec2(2.1 - hit.point.x, hit.point.y - 1.55) * 0.24;
        localUv = floor(localUv * 120) / 120;
        vec3 alb = vec3(0);
        if(uVisorMode == 0.0)
        {
            float mask = fLetters(vec2(2.7 - hit.point.x, hit.point.y - 2.0), 1.0, vec2(1.0));
            alb = vec3(mask + 0.1);
        }
        else if(uVisorMode == 1.0)
        {
            vec2 uv = localUv * 2.0 - 1.0;
            float d = 100.0;
            for(int i = 0 ; i < 10; ++i)
            {
                pR(uv, smoothstep(0.75, 1.0, fract(uBeats * 0.125)) * TAU / 3.0);
                d = min(d, abs(fTriangle(uv, 3.0)));
                uv *= 2.0;
                pR(uv, fract(uBeats * 0.125 * 0.5) * TAU / 3.0);
            }
            alb = vec3(d * 2.0);

            uv = localUv;
            uv.y -= uBallsAnim * 0.125;
            vec2 cell = pMod(uv, 0.1);
            if(cell.y < 0.0)
            {
                float radius = h1(cell);
                alb *= step(step(0.8, radius) * (radius - 0.75) * 4.0, length(uv * 40.0));
            }
        }
        else if(uVisorMode == 2.0)
        {
        }
        alb *= mix(1.0, h1(localUv), uVisorNoise);
        alb = mix(alb, 1.0 - alb, uInverse);
        alb = paletteGameBoy(alb, 8.0);
        return Material(alb, vec3(0.0), 0.1, 0.1, 0.0, 0.0, 0.0);
    }
    if(objectId==3) // AB
        return Material(vec3(0.5, 0.02, 0.15), vec3(0.0), 0.4, 0.1, 0.0, 0.0, 0.0);
    if(objectId==4) // D-pad
        return Material(vec3(0.1), vec3(0.0), 0.4, 0.1, 0.0, 0.0, 0.0);
    if(objectId==5) // start & select
        return Material(vec3(0.2), vec3(0.0), 0.1, 0.7, 0.0, 0.0, 0.0);
    return Material(vec3(0.04, 0.1, 0.14), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
}

const vec2 e=vec2(EPSILON+EPSILON,0.0);
#define IMPL_EMISSIVE_LIGHT(r,f) {vec4 cl;float dE=f(data.hit.point,cl);vec4 taps=vec4(f(data.hit.point+e.xyy),f(data.hit.point+e.yxy),f(data.hit.point+e.yyx),dE);vec3 nE=normalize(taps.xyz-taps.w);r+=DirectionalLight(data,-nE,cl.xyz)/max(1,1+cub(dE));}

vec3 Lighting(LightData data)
{
    vec3 result = vec3(0);
    //result += DirectionalLight(data, vec3(0.5, 1.0, 1.0), vec3(1.0), shadowArgs());
    //result += DirectionalLight(data, vec3(0.5, 1.0, 1.0), vec3(1.0));
    result += PointLight(data, vec3(2.0, 10.0, 15.0), vec3(5.0), 10.0);

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

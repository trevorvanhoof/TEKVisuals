// BOAT
Material MtlBoat(Hit hit)
{
    int objectId = int(hit.materialId.w);
    if(objectId==1) // float
    {
        vec3 alb = vec3(1.0);
        vec2 uv = hit.materialId.xy;
        vec2 s = sign(uv);
        if(s.x!=s.y)
            alb=vec3(1.0,0.2,0.05);
        return Material(alb, vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
    }
    if(objectId==2) // hull
        return Material(vec3(0.3, 0.05, 0.1), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
    if(objectId==3) // rails
        return Material(vec3(0.2), vec3(0.0), 0.5, 0.3, 0.0, 0.0, 0.0);
    if(objectId==4) // planks
        return Material(vec3(1.4, 0.9, 0.5), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 0.0);
    if(objectId==5) // mast
        return Material(vec3(0.2), vec3(0.0), 0.5, 0.3, 0.0, 0.0, 0.0);
    // sail
    return Material(vec3(1.0) + abs(sin(hit.point.z * TAU)), vec3(0.018, 0.1, 0.15), 0.0, 0.0, 0.0, 0.0, 0.0);
}

float fBoat(vec3 p, out vec4 m)
{
    vec3 op = p;

    // float
    p.x = abs(p.x) - 1.4;
    pModInterval(p.z, 2.1, -2, 2);
    float ir,r = fTorus(p.zyx, 0.05, 0.18);
    m=vec4(p.zyx,1);

    // hull
    p=op;
    p.y+=0.5;
    float hull=fCapsule(p.xzy, 1.5, 4.0);
    ir=max(p.y,hull);
    fOpUnion(r,ir,m,vec4(p,2));

    // rails
    p=op;
    p.z=max(0.0,abs(p.z)-4.0);
    pModInterval(p.y, 0.2, -2, 1);
    ir = fTorus(p.xzy, 0.01, 1.5);
    fOpUnion(r,ir,m,vec4(p,3));

    // planks
    p=op;
    p.y+=0.5;
    float cell=pModInterval(p.z, 0.3, -32, 32);
    ir=fBoxChamfer(p,vec3(1.55,0.015,0.08))-0.015;
    ir=max(ir,hull-h1(cell)*0.1);
    fOpUnion(r,ir,m,vec4(p,4));

    // mast & sail
    p=op;
    p.z += 1.5;
    ir=fCapsule(p-vec3(0.0,5.0,0.0),0.08,6.0);
    fOpUnion(r,ir,m,vec4(p,5));
    float tmp=p.y;
    p.y-=5.0;
    float sz=sign(p.z);
    p.z=abs(p.z);
    pR(p.yz, 1.2);
    float bend = max(0.0,cos(p.y)*0.3);
    p.x -= bend;
    ir=max(-ir+0.25+bend,max(-tmp+0.8+sz*0.2,fBox(p,
    vec3(0.01,2.0+sz*0.25,5.0))));
    fOpUnion(r,ir*0.8,m,vec4(p,6));

    return r;
}

// TEK LOGO

float fT(vec2 uv)
{
    // uv = 0 to 1 area the put the character
    vec2 cells = floor(uv * 5.0);
    if(cells.x<0.0||cells.y<0.0||cells.x>4.0||cells.y>4.0)return 0.0;
    if(cells.x == 3.0 || cells.y == 4.0)
        return 1.0;
    return 0.0;
}

float fE(vec2 uv)
{
    // uv = 0 to 1 area the put the character
    vec2 cells = floor(uv * 5.0);
    if(cells.x<0.0||cells.y<0.0||cells.x>4.0||cells.y>4.0)return 0.0;
    if(cells.x == 0.0 || cells.y == 0.0 || cells.y == 2.0 || cells.y == 4.0)
        return 1.0;
    return 0.0;
}

float fK(vec2 uv)
{
    // uv = 0 to 1 area the put the character
    vec2 cells = floor(uv * 5.0);
    if(cells.x<0.0||cells.y<0.0||cells.x>4.0||cells.y>4.0)return 0.0;
    if(cells.x == 0.0 || (cells.x == 4.0 && cells.y == 4.0))
        return 1.0;

    pR(uv, radians(45));
    uv.y -= 0.03;
    float r = step(0.0, -fBox(uv, vec2(2.0, 0.1)));

    pR(uv, radians(90));
    uv.y += 0.65;
    uv.x += 0.4;
    r = max(r, step(0.0, -fBox(uv, vec2(0.3, 0.1))));

    return r;
}

float fLetters(vec2 uv, float localScale, vec2 localOffset)
{
    //uv *= 5.0;

    // warp
    // uv.x+=fract(uv.y*1.0+0.65)*0.15;

    //uv.y += 4.85;
    //uv.x += 1.5;

    float r = fT((uv-0.5)*localScale+0.5-localOffset);
    uv.x -= 1.1;
    r = max(r, fE((uv-0.5)*localScale+0.5-localOffset));
    uv.x -= 1.1;
    r = max(r, fK((uv-0.5)*localScale+0.5-localOffset));
    return r;
}
float fLetters(vec2 uv){return fLetters(uv, 1.0, vec2(0.0));}

// POST EFFECTS

ivec2 pixelateHexagons(vec2 lampSizePx)
{
    // hexagonal pixelation
    //vec2 lampSizePx = vec2(4.0, 5.0) * mix(1.0, 4.0, quad(fract(-uBeats)));
    vec2 uv = gl_FragCoord.xy / lampSizePx;
    vec2 uv2 = uv + vec2(0.5 * sqrt(0.75), 0.75);
    vec2 cell = pMod(uv, vec2(sqrt(0.75), 1.5));
    vec2 cell2 = pMod(uv2, vec2(sqrt(0.75), 1.5));
    float radius = 1.0;
    float r = fHexagon(uv, radius);
    float r1 = fHexagon(uv2, radius);
    if(r1<r){r=r1;cell=cell2;}
    return ivec2(cell * vec2(sqrt(0.75), 1.5) * lampSizePx);
}

vec3 alternateColorizedCells(vec3 cl, vec2 lampSizePx)
{
    if(lampSizePx.x < 0.0 && lampSizePx.y < 0.0)
    {
        vec3 palette[] = vec3[](
        vec3(1.0,0.8,0.3),
        vec3(0.1,1.0,0.3),
        vec3(0.1,0.5,2.0)
        );
        cl = palette[0] * dot(cl, palette[0]) +
             palette[1] * dot(cl, palette[1]) +
             palette[2] * dot(cl, palette[2]);
        return cl * 0.125;
    }

    float r = -0.333;
    vec2 cell = gl_FragCoord.xy;
    if(lampSizePx.x > 0.0 || lampSizePx.y > 0.0)
    {
        vec2 uv = gl_FragCoord.xy / lampSizePx;
        vec2 uv2 = uv + vec2(0.5 * sqrt(0.75), 0.75);
        cell = pMod(uv, vec2(sqrt(0.75), 1.5));
        vec2 cell2 = pMod(uv2, vec2(sqrt(0.75), 1.5));
        float radius = 1.0;
        r = fHexagon(uv, radius);
        float r1 = fHexagon(uv2, radius);
        if(r1<r){r=r1;cell=cell2;}
    }

    vec3 palette[] = vec3[](
    vec3(1.0,0.3,0.0),
    vec3(0.3,1.0,0.3),
    vec3(0.3,0.5,2.0)
    );
    int channel = (int(cell.x)+int(cell.y*0.5))%3;
    cl = palette[channel] * dot(cl, palette[channel]);
    return cl*sat(-r*3.0);
}

vec3 alternateColorizedCells2(vec3 cl, vec2 lampSizePx)
{
    vec2 uv = gl_FragCoord.xy / lampSizePx;
    vec2 uv2 = uv + vec2(0.5 * sqrt(0.75), 0.75);
    vec2 cell = pMod(uv, vec2(sqrt(0.75), 1.5));
    vec2 cell2 = pMod(uv2, vec2(sqrt(0.75), 1.5));
    float radius = 1.0;
    float r = fHexagon(uv, radius);
    float r1 = fHexagon(uv2, radius);
    if(r1<r){r=r1;cell=cell2;}

    vec3 palette[] = vec3[](
    vec3(2.0,0.4,0.1),
    vec3(0.4,1.0,0.2),
    vec3(0.2,0.2,1.5)
    );
    int channel = (int(cell.x)+int(cell.y*0.5))%3;
    cl=palette[channel] * dot(cl,palette[channel]);
    return cl*sat(-r*3.0);
}

vec3 hexagonOverlay(vec3 cl, vec2 lampSizePx)
{
    //vec2 lampSizePx = vec2(32.0, 32.0);
    vec2 uv = gl_FragCoord.xy / lampSizePx;
    vec2 uv2 = uv + vec2(0.5 * sqrt(0.75), 0.75);
    pMod(uv, vec2(sqrt(0.75), 1.5));
    pMod(uv2, vec2(sqrt(0.75), 1.5));
    float s = 0.8;
    cl *= 1.0 - 4.0 * max(0.0, min(fHexagon(uv, s), fHexagon(uv2, s)));
    s = 0.99;
    cl += max(0.0, min(fHexagon(uv, s), fHexagon(uv2, s)));
    cl *= 1.0 + 4.0 * max(0.0, min(fHexagon(uv, s), fHexagon(uv2, s)));
    return cl;
}

vec3 rgbLinesY(vec3 cl, float pixelate)
{
    ivec2 texl = ivec2(gl_FragCoord.xy) / max(1,int(pixelate));
    // glitch
    float offset = abs((float(texl.y) / (uResolution.y / pixelate)) - uBeats);
    // separate rgb
    int channel = int(texl.x + offset) % 3;
    vec3 zero = vec3(0.0);
    zero[channel] = cl[channel];
    return zero*3.0;
}

vec3 paletteRGB(vec3 cl, float noise, float lumaInfluence)
{
    // palletize
    #define N 8
    vec3 palette[N] = vec3[N](
    vec3(1,0,0),
    vec3(0,1,0),
    vec3(0,0,1),
    vec3(1,1,0),
    vec3(0,1,1),
    vec3(1,0,1),
    vec3(1,1,1),
    vec3(0,0,0)
    );
    float bestChoice = 10.0;
    int bestIndex = 0;
    cl = sat(cl*((1.0-noise)+h3(gl_FragCoord.xy)*(noise+noise)));
    for(int i = 0; i < N; ++i)
    {
        float choice=length(cl-palette[i]);
        if(choice<bestChoice){bestChoice=choice;bestIndex=i;}
    }
    #undef N
    return palette[bestIndex] * mix(1.0, dot(cl, palette[bestIndex]), lumaInfluence);
}

vec3 paletteGameBoy(vec3 cl, float ditherPixelSize)
{
    // map clr to palette (& dither)
    // float ditherPixelSize = 4.0;
    vec2 ditherCell = floor(fract(gl_FragCoord.xy / ditherPixelSize) * 2.0);
    bool dither = (ditherCell.x != ditherCell.y);

    // luminance mapped to gameboy colors
    vec3 p0 = vec3(0,0,0)/255.;
    vec3 p1 = vec3(15,56,15)/255.;
    vec3 p2 = vec3(48,98,48)/255.;
    vec3 p3 = vec3(139,172,15)/255.;
    vec3 p4 = vec3(155,188,15)/255.;
    vec3 p5 = vec3(202,220,159)/255.;

    float luminance = 0.2126 * cl.x + 0.7152 * cl.y + 0.0722 * cl.z;
    luminance = pow(sat(luminance), 0.7);
    luminance *= 5.999;
    if(dither)
      luminance += 0.5;

    int idx = int(floor(luminance));
    switch(idx)
    {
    case 0:
      return p0;
    case 1:
      return p1;
    case 2:
      return p2;
    case 3:
      return p3;
    case 4:
      return p4;
    default:
      return p5;
    }
}
vec3 paletteC64(vec3 cl, float noise, float lumaInfluence, float pixelate)
{
    // palletize
    #define N 16
    vec3 palette[N] = vec3[N](
    vec3(1)/255.0,
    vec3(255)/255.0,
    vec3(136,1,1)/255.0,
    vec3(170,255,238)/255.0,
    vec3(204,68,204)/255.0,
    vec3(1,204,85)/255.0,
    vec3(1,1,170)/255.0,
    vec3(238,238,119)/255.0,
    vec3(221,136,85)/255.0,
    vec3(102,68,1)/255.0,
    vec3(255,119,119)/255.0,
    vec3(51)/255.0,
    vec3(119)/255.0,
    vec3(170,255,102)/255.0,
    vec3(1,136,255)/255.0,
    vec3(187)/255.0
    );
    float bestChoice = 10.0;
    int bestIndex = 0;
    cl = sat(cl*((1.0-noise)+h3(ivec2(gl_FragCoord.xy) / max(1,int(pixelate)))*(noise+noise)));
    for(int i = 0; i < N; ++i)
    {
        float choice=length(cl-palette[i]);
        if(choice<bestChoice){bestChoice=choice;bestIndex=i;}
    }
    #undef N
    return palette[bestIndex] * mix(1.0, dot(cl, palette[bestIndex]), lumaInfluence);
}

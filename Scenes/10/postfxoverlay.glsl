// Pass that forwards the texture by default, but allows injection of additional filters.

//uniform float uPostPixelate;
//uniform float uHexOverlay;
uniform float uColorizeMode;
//uniform vec2 uPostHexagonSize;

vec3 alternateColorizedCells3(vec3 cl, vec2 lampSizePx)
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
    vec3(0.5, 0.1, 0.5),
    vec3(0.1, 1.5, 0.5),
    vec3(0.5, 0.1, 2.0)
    );
    int channel = (int(cell.x)+int(cell.y*0.5))%3;
    cl=palette[channel] * dot(outColor0.xyz,palette[channel]);
    return cl*sat(-r*3.0);
}

void main()
{
    vec2 uv = vec2(gl_FragCoord.xy / uResolution);
    if(uColorizeMode == 2.0)
        uv += quad(snoise(uBeats + 100.0 * h1(floor(uv * 10.0))) - 0.5);
    outColor0 = texture(uImages[0], uv);
    if(uColorizeMode == 0.0)
        outColor0.xyz = paletteGameBoy(outColor0.xyz, 1.0);
    if(uColorizeMode == 2.0)
        outColor0.xyz = alternateColorizedCells3(outColor0.xyz, vec2(4,6));

    /*if(uHexOverlay!=0.0)
    outColor0.xyz = hexagonOverlay(outColor0.xyz, uPostHexagonSize);

    if(uColorizeMode>3.0)
    outColor0.xyz = alternateColorizedCells2(outColor0.xyz, uPostHexagonSize);
    else if(uColorizeMode>2.0)
    outColor0.xyz = alternateColorizedCells(outColor0.xyz, uPostHexagonSize);
    else if(uColorizeMode>1.0)
    outColor0.xyz = rgbLinesY(outColor0.xyz, uPostPixelate);
    else if(uColorizeMode>0.0)
    outColor0.xyz = paletteC64(outColor0.xyz, 0.2, 0.0, uPostPixelate);*/
}

// Pass that forwards the texture by default, but allows injection of additional filters.

uniform float uPostPixelate;
uniform float uHexOverlay;
uniform float uColorizeMode;
uniform vec2 uPostHexagonSize;

void main()
{
    ivec2 texl = (uPostHexagonSize.x>0.0&&uPostHexagonSize.y>0.0)?pixelateHexagons(uPostHexagonSize):ivec2(gl_FragCoord.xy);
    outColor0 = texelFetch(uImages[0],texl,0);

    if(uHexOverlay!=0.0)
    outColor0.xyz = hexagonOverlay(outColor0.xyz, uPostHexagonSize);

    if(uColorizeMode>3.0)
    outColor0.xyz = paletteGameBoy(outColor0.xyz, uPostPixelate);
    else if(uColorizeMode>2.0)
    outColor0.xyz = alternateColorizedCells(outColor0.xyz, uPostHexagonSize);
    else if(uColorizeMode>1.0)
    outColor0.xyz = rgbLinesY(outColor0.xyz, uPostPixelate);
    else if(uColorizeMode>0.0)
    outColor0.xyz = paletteC64(outColor0.xyz, 0.2, 0.0, uPostPixelate);
}

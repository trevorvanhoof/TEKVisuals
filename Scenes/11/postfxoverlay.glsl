// Pass that forwards the texture by default, but allows injection of additional filters.
uniform float uPixelate = 16;
uniform float uPalettize = 0;
void main()
{
    ivec2 texl = ivec2(gl_FragCoord.xy);

    if(uPixelate==0)
    {
        outColor0 = texelFetch(uImages[0],texl,0);
    }
    else
    {
        ivec2 quantize = ivec2(uPixelate,uPixelate+uPixelate);
        ivec2 local = texl%quantize;
        ivec2 cell = texl/quantize;
        float d = 1.0;
        if(local.x==0||local.y==0)d=2.0 / uPixelate;
        if(local.x>8&&local.y<8)d=2.0 / uPixelate;
        vec4 mask = vec4(d,d,d,0.0);
        vec3 palette[] = vec3[](
        vec3(1.0, 0.2, 0.2),
        vec3(0.2, 1.0 ,0.2),
        vec3(0.2, 0.2 ,1.0));
        mask.xyz *= palette[cell.x%3];
        outColor0 = texelFetch(uImages[0],cell*quantize,0)*mask;
    }

    if(uPalettize != 0.0)
        outColor0.xyz = paletteGameBoy(outColor0.xyz, max(1,uPixelate));
}

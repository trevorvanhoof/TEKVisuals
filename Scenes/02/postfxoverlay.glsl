uniform float uPostMode = 0.0;
// Pass that forwards the texture by default, but allows injection of additional filters.
void main()
{
    ivec2 uv = ivec2(gl_FragCoord.xy);
    //uv = ivec2(uv/vec2(8,4))*ivec2(8,4);
    outColor0 = texelFetch(uImages[0],uv,0);
    vec2 _uv = (uFishEye>0.0) ? FishEyeUV(uFishEye) : (gl_FragCoord.xy / uResolution);

    //outColor0 *= 0.25 + 0.75 * quad(abs(sin(_uv.y * uResolution.y / 8.0 * PI + uBeats * TAU)));
    //outColor0 = pow(vec4(2.0), floor(log2(outColor0)*0.5)*3.0)*4.0;

    outColor0 *= 0.5 + 0.5 * quad(abs(sin(_uv.y * uResolution.y / 8.0 * PI + uBeats * TAU)));

    if(uPostMode == 0.0)
        outColor0 = pow(vec4(2.0), floor(log2(outColor0)));
    else if(uPostMode == 1.0)
        outColor0.xyz = paletteGameBoy(pow(outColor0.xyz * 2.0, vec3(0.65)), 2.0);
}

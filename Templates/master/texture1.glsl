void main()
{
    vec2 p=gl_FragCoord.xy/uResolution;
    float a = perlin(p,10,16,2,.5) * 0.5 + billows(p,10,5,2,.5);
    float b = perlin(p,10,16,2,.5) * 0.5 + billows(p,10,5,2,.5);
    float c = billows(p,2,3,2,.5);
    outColor0=vec4(a,b,c,0);
}

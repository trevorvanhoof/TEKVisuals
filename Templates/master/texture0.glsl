float B(float g,vec2 p)
{
    return cub(billows(p-g*0.025,vec2(4),7,2,.5)+perlin(p-g*0.025,vec2(8),13,2,.5));
}

void main()
{
    vec2 p=gl_FragCoord.xy/uResolution;

    float r = perlin(abs(p-.5)+perlin(p,7,16,2,.5),10,16,2,.4);
    float g = billows(p,vec2(16),5,2,.7);
    float b = B(g,p);
    outColor0=vec4(
    r,
    g,
    b,
    pow(perlin(p,vec2(300,32),3,2,.5), 8.)
    );
}

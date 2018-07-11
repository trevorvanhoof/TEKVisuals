float fLetters(float localScale, vec2 localOffset)
{
    vec2 uv = (gl_FragCoord.xy*2.0-uResolution)/uResolution.y;
    uv *= 5.0;

    // warp
    // uv.x+=fract(uv.y*1.0+0.65)*0.15;

    uv.y += 4.85;
    uv.x += 1.5;

    return fLetters(uv, localScale, localOffset);
}

void main()
{
    outColor0=texelFetch(uImages[0],ivec2(gl_FragCoord.xy),0);

    // map clr to palette (& dither)
    float ditherPixelSize = 4.0;
    vec2 ditherCell = floor(fract(gl_FragCoord.xy / ditherPixelSize) * 2.0);
    bool dither = (ditherCell.x != ditherCell.y);

    // luminance mapped to gameboy colors
    vec3 p0 = vec3(0,0,0)/255.;
    vec3 p1 = vec3(15,56,15)/255.;
    vec3 p2 = vec3(48,98,48)/255.;
    vec3 p3 = vec3(139,172,15)/255.;
    vec3 p4 = vec3(155,188,15)/255.;
    vec3 p5 = vec3(202,220,159)/255.;

    float luminance = 0.2126 * outColor0.x + 0.7152 * outColor0.y + 0.0722 * outColor0.z;
    luminance = pow(sat(luminance), 0.7);
    luminance *= 5.999;
    if(dither)
      luminance += 0.5;

    int idx = int(floor(luminance));
    switch(idx)
    {
    case 0:
      outColor0.xyz=p0;
      break;
    case 1:
      outColor0.xyz=p1;
      break;
    case 2:
      outColor0.xyz=p2;
      break;
    case 3:
      outColor0.xyz=p3;
      break;
    case 4:
      outColor0.xyz=p4;
      break;
    default:
      outColor0.xyz=p5;
      break;
    }

    // overlay
    outColor0.xyz = mix(outColor0.xyz, p0, smoothstep(0.0, 1.0 / uResolution.y,
    fLetters(1.0, vec2(0.0))));
    outColor0.xyz = mix(outColor0.xyz, p4, smoothstep(0.0, 1.0 / uResolution.y,
    fLetters(1.1, vec2(0.0, 0.05))));
}

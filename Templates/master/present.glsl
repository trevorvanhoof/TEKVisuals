uniform float uSaturation = 1.0;
uniform float uLuminance = 1.0;
uniform float uOffset = 0.0;
// uniform float uExposure = 1.0;
uniform float uGamma = 1.0;

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm( vec3 x )
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return sat((x*(a*x+b))/(x*(c*x+d)+e));
}

// Good & fast sRgb approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html
vec3 LinearToSRGB(vec3 rgb)
{
    rgb=max(rgb,vec3(0,0,0));
    return max(1.055*pow(rgb,vec3(0.416666667))-0.055,0.0);
}

void main()
{
    vec3 color = texelFetch(uImages[0],ivec2(gl_FragCoord.xy),0).xyz;
    color = LinearToSRGB(ACESFilm(color * uLuminance));
    color = pow(hsv2rgb(rgb2hsv(color) * vec3(1.0, uSaturation, 1.0) + vec3(0.0, 0.0, uOffset)), vec3(uGamma));
    outColor0=vec4((color),1.0);
}

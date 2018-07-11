// Pass that forwards the texture by default, but allows injection of additional filters.
void main()
{
    outColor0=texelFetch(uImages[0],ivec2(gl_FragCoord.xy),0);
}

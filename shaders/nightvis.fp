void main()
{
	FragColor = texture(InputTexture, TexCoord);
	FragColor.r *= 0.4;
	FragColor.g *= 1;
	FragColor.b *= 0.4;
}

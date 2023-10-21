void main()
{
	FragColor = texture(InputTexture, TexCoord);
	FragColor.r *= 1.0 + 3.5 * strength;
	FragColor.g *= 1.0 - 0.7 * strength;
	FragColor.b *= 1.0 - 0.7 * strength;
}

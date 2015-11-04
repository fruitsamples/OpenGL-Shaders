#include <GLUT/glut.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct  {
	char	*name;
	float 	*palette;
} PaletteRec;

GLuint		texid, height, width, palette_index = 0;

PaletteRec  palettes[] = 
	{
		{"palette: Gamma = 1.0", NULL },
		{"palette: Gamma = 0.5", NULL },
		{"palette: Gamma = 0.75", NULL },
		{"palette: Gamma = 1.2", NULL },
		{"palette: Gamma = 1.5", NULL },
		{"palette: Gamma = 1.8", NULL },
		{"palette: Gamma = 2.0", NULL },
		{"palette: Gamma = 2.5", NULL },
		{"palette: Gamma = 3.0", NULL },
		{"palette: Darken", NULL },
		{"palette: Lighten", NULL },
		{"palette: Inverse", NULL },
		{"palette: Red Only", NULL },
		{"palette: Green Only", NULL },
		{"palette: Blue Only", NULL },
		{"palette: Blue and Green Only", NULL },
		{ NULL, NULL },
	};

void MakeDarkenPalette(float **newpalette)
{
	int i;
	float step = 1.0 / 255.0;
	float *palette = malloc(256* 3 * sizeof(GLfloat));
	float *p = palette;
	
	for (i=0; i < 256; i++)
	{
		p[0] = p[1] = p[2] = (float) i * step * 0.75;
		p += 3;
	}
	
	*newpalette = palette;
}

void MakeLightenPalette(float **newpalette)
{
	int i;
	float step = 1.0 / 255.0;
	float *palette = malloc(256* 3 * sizeof(GLfloat));
	float *p = palette;
	
	for (i=0; i < 256; i++)
	{
		float f = (float) i * step * 1.2;
		if (f>1.0) f = 1.0;
		p[0] = p[1] = p[2] = f;
		p += 3;
	}
	
	*newpalette = palette;
}

void MakeInversePalette( float **newpalette )
{
	int i;
	float step = 1.0 / 255.0;
	float *inversepalette = malloc(256* 3 * sizeof(GLfloat));
	float *p = inversepalette;
	
	for (i=0; i < 256; i++)
	{
		p[0] = p[1] = p[2] = (float) (255 - i) * step;
		p += 3;
	}
	
	*newpalette = inversepalette;
}

void MakeMaskedChannelPalette( float **newpalette, GLboolean red, GLboolean green, GLboolean blue )
{
	int i;
	float step = 1.0 / 255.0;
	float *palette = malloc(256* 3 * sizeof(GLfloat));
	float *p = palette;
	
	for (i=0; i < 256; i++)
	{
		if (red) p[0] = step * (float)i; else p[0] = 0.0;
		if (green) p[1] = step * (float)i; else p[1] = 0.0;
		if (blue) p[2] = step * (float)i; else p[2] = 0.0;
		p += 3;
	}
	
	*newpalette = palette;
}

void MakeGammaPalette( float **newpalette, float gamma )
{
	int i;
	float step = 1.0 / 255.0;
	float *gammapalette = malloc(256* 3 * sizeof(GLfloat));
	float *p = gammapalette;
	float oneOverGamma = 1.0/gamma;
	
	for (i=0; i < 256; i++)
	{
		float f, g;
		f = (float) i * step; //convert [0, 255] to [0.0, 1.0];
		g = pow( f , oneOverGamma);
		if (g > 1.0) g = 1.0;
		p[0] = p[1] = p[2] = g;
		p += 3;
	}
	
	*newpalette = gammapalette;
}

void TextureFromFile(char * name, GLuint *textureID, GLuint *width, GLuint *height) 
{
	CFStringRef			path;
	CFURLRef			url;
	CGImageSourceRef	cgImageSource;
	CGImageRef			cgImage;
	CGContextRef		cgContext;
	CGColorSpaceRef		colorSpace;
	int					w, h, rowbytes;
	GLubyte				*buffer;
	
	path = CFStringCreateWithCString(NULL, name, kCFStringEncodingMacRoman);
	url = CFURLCopyAbsoluteURL(CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, false));
	cgImageSource = CGImageSourceCreateWithURL(url, NULL);
	
	if (cgImageSource == NULL)
		return;

	cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, NULL);
	if (cgImage == NULL)
		return;
   
	w = CGImageGetWidth(cgImage);
	h = CGImageGetHeight(cgImage);
	rowbytes = w * 4 * sizeof(GLubyte);
	buffer = malloc(rowbytes * h);
	colorSpace = CGColorSpaceCreateDeviceRGB();
   
	cgContext = CGBitmapContextCreate (buffer, w, h, 8, rowbytes, colorSpace, kCGImageAlphaPremultipliedFirst);
	CGContextDrawImage( cgContext, CGRectMake(0, 0, w, h), cgImage);

	glGenTextures(1, textureID);
#if __BIG_ENDIAN__
	glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, w, h, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, buffer);
#else
	glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, w, h, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, buffer);
#endif
	glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   
	free(buffer);

	if (url) CFRelease(url);
	if (cgImageSource) CFRelease(cgImageSource);
	if (cgImage) CFRelease(cgImage);
	if (cgContext) CFRelease(cgContext);
	if (colorSpace) CFRelease(colorSpace);
	
	*width = w;
	*height = h;
}

void DrawStr(const char *str, float x, float y)
{
	GLint i = 0;
	
	if(!str) return;
	
	glRasterPos2f(x, y);
	glColor3f(1.0, 1.0, 1.0);
	while(str[i])
	{
		glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, str[i]);
		i++;
	}
}
GLboolean HasARBFP(void)
{
	const GLubyte* extensions = glGetString(GL_EXTENSIONS);
	
	return gluCheckExtension((GLubyte*)"GL_ARB_fragment_program", extensions);
}

void init(void) 
{
	int err;
	GLubyte fragment_program[] = 
		"!!ARBfp1.0\n"
		"TEMP sourcecolor, palettecolor;\n"
		"TEX sourcecolor, fragment.texcoord[0], texture[0], RECT;\n"
		"TEX palettecolor.r, sourcecolor.r, texture[1], 1D;\n"
		"TEX palettecolor.g, sourcecolor.g, texture[1], 1D;\n"
		"TEX palettecolor.b, sourcecolor.b, texture[1], 1D;\n"
		"MOV result.color, palettecolor;\n"
		"MOV result.color.a, sourcecolor.a;\n"
		"END\n";

	glClearColor (0.0, 0.0, 0.0, 0.0);
	
	if ( !HasARBFP())
	{
		printf ("%s doesn't support ARB_fragment_program\n", glGetString(GL_RENDERER));
		exit(1);
	}

	glProgramStringARB(GL_FRAGMENT_PROGRAM_ARB, GL_PROGRAM_FORMAT_ASCII_ARB, strlen((char*)fragment_program), fragment_program);	
	err = glGetError();
	if(err) 
	{
		printf("glProgramStringARB returned error:\n%s\n", glGetString(GL_PROGRAM_ERROR_STRING_ARB));
		exit (1);
	}
	
	
	glActiveTexture(GL_TEXTURE0);
	TextureFromFile("rose.jpg", &texid, &width, &height);
	
	int i = 0;
	MakeGammaPalette(&palettes[i++].palette, 1.0);
	MakeGammaPalette(&palettes[i++].palette, 0.5);
	MakeGammaPalette(&palettes[i++].palette, 0.75);
	MakeGammaPalette(&palettes[i++].palette, 1.2);
	MakeGammaPalette(&palettes[i++].palette, 1.5);
	MakeGammaPalette(&palettes[i++].palette, 1.8);
	MakeGammaPalette(&palettes[i++].palette, 2.0);
	MakeGammaPalette(&palettes[i++].palette, 2.5);
	MakeGammaPalette(&palettes[i++].palette, 3.0);
	MakeDarkenPalette(&palettes[i++].palette);
	MakeLightenPalette(&palettes[i++].palette);
	MakeInversePalette(&palettes[i++].palette);
	MakeMaskedChannelPalette(&palettes[i++].palette, GL_TRUE, GL_FALSE, GL_FALSE);
	MakeMaskedChannelPalette(&palettes[i++].palette, GL_FALSE, GL_TRUE, GL_FALSE);
	MakeMaskedChannelPalette(&palettes[i++].palette, GL_FALSE, GL_FALSE, GL_TRUE);
	MakeMaskedChannelPalette(&palettes[i++].palette, GL_FALSE, GL_TRUE, GL_TRUE);

	glActiveTexture(GL_TEXTURE1);
	glTexImage1D( GL_TEXTURE_1D, 0, GL_RGB, 256, 0, GL_RGB, GL_FLOAT, palettes[0].palette);
	glTexParameteri( GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri( GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
 }

void display(void)
{
	float aspect = ((float) height / (float) width);
	glClear (GL_COLOR_BUFFER_BIT);

	//Draw the source quad with no texture (no fragment program active);
	glActiveTexture(GL_TEXTURE0);
	glEnable(GL_TEXTURE_RECTANGLE_ARB);
	glBegin(GL_QUADS);
		glTexCoord2i( 0, height);
		glVertex2f(-0.9, -0.7);
		glTexCoord2f( width, height);
		glVertex2f(-0.6, -0.7);
		glTexCoord2f( width, 0);
		glVertex2f(-0.6, -0.7 + (0.3 * aspect));
		glTexCoord2f( 0, 0);
		glVertex2f(-0.9, -0.7 + (0.3 * aspect));
	glEnd();
	glDisable(GL_TEXTURE_RECTANGLE_ARB);
	glColor3f(0.8, 0.8, 0.8);
	DrawStr("source texture", -0.9, -0.8);
	
	//Draw the palette
	float x, y, size = 0.05;
	x = -0.3;
	y = -0.55;
	glActiveTexture(GL_TEXTURE1);
	glEnable(GL_TEXTURE_1D);
	//To draw only get the one channel of the palette at a time, I set the texture mode to
	// GL_MODULATE and set the fragment color to zero for the channels I don't want to
	// show.
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor3f(1,0,0);
	glBegin(GL_QUADS);
		glMultiTexCoord1f(GL_TEXTURE1, 0.0); glVertex2f(x, y);
		glMultiTexCoord1f(GL_TEXTURE1, 1.0); glVertex2f(0.8, y);
		glMultiTexCoord1f(GL_TEXTURE1, 1.0); glVertex2f(0.8, y+size);
		glMultiTexCoord1f(GL_TEXTURE1, 0.0); glVertex2f(x, y+size);
	glEnd();
	glColor3f(0,1,0);
	y = y - size;
	glBegin(GL_QUADS);
		glMultiTexCoord1f(GL_TEXTURE1, 0.0); glVertex2f(x, y);
		glMultiTexCoord1f(GL_TEXTURE1, 1.0); glVertex2f(0.8, y);
		glMultiTexCoord1f(GL_TEXTURE1, 1.0); glVertex2f(0.8, y+size);
		glMultiTexCoord1f(GL_TEXTURE1, 0.0); glVertex2f(x, y+size);
	glEnd();
	glColor3f(0,0,1);
	y = y - size;
	glBegin(GL_QUADS);
		glMultiTexCoord1f(GL_TEXTURE1, 0.0); glVertex2f(x, y);
		glMultiTexCoord1f(GL_TEXTURE1, 1.0); glVertex2f(0.8, y);
		glMultiTexCoord1f(GL_TEXTURE1, 1.0); glVertex2f(0.8, y+size);
		glMultiTexCoord1f(GL_TEXTURE1, 0.0); glVertex2f(x, y+size);
	glEnd();
	glDisable(GL_TEXTURE_1D);
	glColor3f(0.8, 0.8, 0.8);
	DrawStr(palettes[palette_index].name, -0.3, -0.8);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
 
	//draw the quad using the fragment program to do the palette lookup
	glEnable(GL_FRAGMENT_PROGRAM_ARB);

	glBegin(GL_QUADS);
		glMultiTexCoord2i(GL_TEXTURE0, 0, height);
		glVertex2f(-0.8, -0.2);
		glMultiTexCoord2i(GL_TEXTURE0, width, height);
		glVertex2f(0.8, -0.2);
		glMultiTexCoord2i(GL_TEXTURE0, width, 0);
		glVertex2f(0.8, -0.2 + (1.6 * aspect));
		glMultiTexCoord2i(GL_TEXTURE0, 0.0, 0);
		glVertex2f(-0.8,  -0.2 + (1.6 * aspect));
	glEnd();
	glDisable(GL_FRAGMENT_PROGRAM_ARB);

	glColor3f(0.8, 0.8, 0.8);
	DrawStr("space bar to cycle through different palettes", -0.9, -0.95);

	glFlush ();
}

void reshape (int w, int h)
{
	glViewport (0, 0, (GLsizei) w, (GLsizei) h); 
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();             /* clear the matrix */
}

void keyboard(unsigned char key, int x, int y)
{
	switch (key) 
	{
		case ' ':
			palette_index++;
			if (palettes[palette_index].name == NULL)
				palette_index = 0;
			glActiveTexture(GL_TEXTURE1);
			glTexImage1D( GL_TEXTURE_1D, 0, GL_RGB, 256, 0, GL_RGB, GL_FLOAT, palettes[palette_index].palette);
			break;
		case 27:
			exit(0);
			break;
	}
	glutPostRedisplay();
}

int main(int argc, char** argv)
{
   glutInit(&argc, argv);
   glutInitDisplayMode (GLUT_SINGLE | GLUT_RGB);
   glutInitWindowSize (500, 500); 
   glutInitWindowPosition (100, 100);
   glutCreateWindow ("Fragment Program Palette");
   init();
   glutDisplayFunc(display); 
   glutReshapeFunc(reshape);
   glutKeyboardFunc(keyboard);
   glutMainLoop();
   return 0;
}

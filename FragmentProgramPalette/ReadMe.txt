This program uses ARB_fragment_program to apply a color palette to an image. 
The image is loaded from a file on disk using CoreGraphics and ImageIO in the
TextureFromFile routine.  The resulting image is bound as a rectangle texture 
to texture unit 0.  

Several different palettes are created in the init() routine.  They are all
256 entry palettes with a separate lookup for R, G, and B.  The palettes are 
bound one at a time as 1D textures to texture unit 1.


The fragment program itself is simple:

1	!!ARBfp1.0
2	TEMP sourcecolor, palettecolor;
3	TEX sourcecolor, fragment.texcoord[0], texture[0], RECT;
4	TEX palettecolor.r, sourcecolor.r, texture[1], 1D;
5	TEX palettecolor.g, sourcecolor.g, texture[1], 1D;
6	TEX palettecolor.b, sourcecolor.b, texture[1], 1D;
7	MOV result.color, palettecolor;
8	MOV result.color.a, sourcecolor.a;
9	END


Line 2 is the read of the texel from the original Rose rectangle texture.  
Lines 4, 5, and 6 perform the lookup into the 1D color table.  The color value
from the orignal image is used as the texture coordinate into the color table.
Since a fragment program needs to fully specify the output color, I added 
line 9.
This program attempts to illustrate a very simple use of GLSL that 
might be useful to develop and debug shaders or as a starting point using
GLSL in your program.


The init() routine loads two simple shaders:

Vertex shader:

1	varying vec3 color;
2	void main(void)
3	{
4		color = vec3(gl_Vertex.x,gl_Vertex.y, gl_Vertex.x*gl_Vertex.y);
5		gl_Position = ftransform();
6	};

Fragment shader:

1	varying vec3 color;
2	void main (void)
3	{
4		gl_FragColor = vec4 (color, 1.0);
5	};


In line 4 of the vertex shader, it constructs a color based on the polygon
coordinates and passes it to the fragment shader.  The use of "varying" 
causes that value to be interpolated across the polygon.  The fragment shader
simply uses that value as the fragment color.
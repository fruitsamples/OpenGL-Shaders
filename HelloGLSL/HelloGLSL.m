#include <GLUT/glut.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <stdlib.h>
#include <stdio.h>

GLhandleARB     fragShader;
GLhandleARB     vertShader;
GLhandleARB     program;
GLboolean		glsl_enabled = GL_TRUE;

GLboolean HasGLSL(void)
{
	const GLubyte* extensions = glGetString(GL_EXTENSIONS);
	
	if (GL_FALSE == gluCheckExtension((const GLubyte*) "GL_ARB_shader_objects", extensions))
		return GL_FALSE;
	if (GL_FALSE == gluCheckExtension((const GLubyte*)"GL_ARB_vertex_shader", extensions))
		return GL_FALSE;
	if (GL_FALSE == gluCheckExtension((const GLubyte*)"GL_ARB_fragment_shader", extensions))
		return GL_FALSE;
	if (GL_FALSE == gluCheckExtension((const GLubyte*)"GL_ARB_shading_language_100", extensions))
		return GL_FALSE;
	
	return GL_TRUE;
}

#define FailGLError(X) {int err = (int)glGetError(); \
	if (err != GL_NO_ERROR) \
		{printf(X); printf(" error 0x%x\n",err); \
		return err;} }
#define FailWithMessage(X) { printf(X); printf("\n"); return 1;}
#define FailOnErrWithMessage(X,message) { if (X!=0) {printf(message); printf("\n"); return 1;}}

GLenum LinkProgram(GLhandleARB program)
{
	GLint	logLength;
	GLint linked;
	
	glLinkProgramARB(program);
	FailGLError("Failed glLinkProgramARB");
	glGetObjectParameterivARB(program,GL_OBJECT_LINK_STATUS_ARB,&linked);
	glGetObjectParameterivARB(program,GL_OBJECT_INFO_LOG_LENGTH_ARB,&logLength);
	if (logLength)
	{
		GLint	charsWritten;
		GLcharARB *log = malloc(logLength+128);
		
		glGetInfoLogARB(program, logLength, &charsWritten, log);
		printf("Link GetInfoLogARB:\n%s\n",log);
		free (log);
	}
	if (!linked) 
		FailWithMessage("shader did not link");
	return GL_NO_ERROR;
}

GLenum CompileProgram(GLenum target, GLcharARB* sourcecode, GLhandleARB *shader)
{
	GLint	logLength;
	GLint	compiled;

	if (sourcecode != 0)
	{
		*shader = glCreateShaderObjectARB(target);
		FailGLError("Failed to create fragment shader");
		glShaderSourceARB(*shader,1,(const GLcharARB **)&sourcecode,0);
		FailGLError("Failed glShaderSourceARB");
		glCompileShaderARB(*shader);
		FailGLError("Failed glCompileShaderARB");

		glGetObjectParameterivARB(*shader,GL_OBJECT_COMPILE_STATUS_ARB,&compiled);
		glGetObjectParameterivARB(*shader,GL_OBJECT_INFO_LOG_LENGTH_ARB,&logLength);
		if (logLength)
		{
			GLcharARB *log = malloc(logLength+128);
			glGetInfoLogARB(*shader, logLength, &logLength, log);
			printf("Compile log: \n");
			free (log);
		}
		if (!compiled)
			FailWithMessage("shader could not compile");
		
	}
	return GL_NO_ERROR;
}


int init(void) 
{
	int err;
	char v[] =
		"varying vec3 color;\n"
		"void main(void)\n"
		"{\n"
		"   color = vec3(gl_Vertex.x, 0.25, gl_Vertex.y);\n"
		"	gl_Position = ftransform();\n"
		"}\n";

	char f[] =
		"varying vec3 color;\n"
		"void main (void)\n"
		"{\n"
		"		gl_FragColor = vec4 (color, 1.0);\n"
		"}\n";


	glClearColor (0.0, 0.0, 0.0, 0.0);
	glColor3f (0.250, 0.65, 1.0);
	
	if ( ! HasGLSL())
	{
		printf ("%s doesn't support GLSL\n", glGetString(GL_RENDERER));
		exit(1);
	}
	err = CompileProgram(GL_VERTEX_SHADER_ARB, v, &vertShader);
	if (0 != err)
	{
		printf ("Vertex Shader could not compile");
		exit (1);
	}
	err = CompileProgram(GL_FRAGMENT_SHADER_ARB, f, &fragShader);
	if (0 != err)
	{
		printf ("Fragment Shader could not compile");
		exit (1);
	}
	
	program = glCreateProgramObjectARB();
	glAttachObjectARB(program,vertShader);
	glAttachObjectARB(program,fragShader);
	
	err = LinkProgram(program);
	if (GL_NO_ERROR != err)
	{
		printf ("Program could not link");
		exit (1);
	}
	
	glUseProgramObjectARB(program);
	return glGetError();
}

void display(void)
{
	glClear (GL_COLOR_BUFFER_BIT);

	glBegin(GL_TRIANGLES);
		glVertex2f(0.0, 0.0);
		glVertex2f(0.0, 0.8);
		glVertex2f(0.8, 0.0);
	glEnd();

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
			glsl_enabled = !glsl_enabled;
			glsl_enabled ? glUseProgramObjectARB(program) : glUseProgramObjectARB(0);
			
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
   glutCreateWindow (argv[0]);
   if (init () == GL_NO_ERROR)
   {
	   glutDisplayFunc(display); 
	   glutReshapeFunc(reshape);
	   glutKeyboardFunc(keyboard);
	   glutMainLoop();
   }
   return 0;
}

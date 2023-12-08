#version 450

in vec2 pos;
in vec2 uv;
uniform mat4 mproj;
out vec2 tuv;

void main(){
	gl_Position = mproj * vec4(pos, 0, 1);
	tuv = uv;
}
#version 450

precision mediump float;

uniform sampler2D tex;

in vec2 tuv;
out vec4 fragmentColor;
void main(){	
    fragmentColor = texture(tex, tuv);
}
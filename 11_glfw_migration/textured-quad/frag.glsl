#version 410 core

in vec2 texcoord;
out vec4 frag_color;

uniform sampler2D texture0;

void main() {
    frag_color = texture(texture0, texcoord);
}

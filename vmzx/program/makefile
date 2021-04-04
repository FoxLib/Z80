NAME=01_hello
FF1=ffmpeg -framerate 50 -r 50 -i
FF2=-f mp4 -q:v 0 -vcodec mpeg4 -y

all:
	./../bas2tap/bas2tap -q $(NAME).bas ../program.tap
	cd .. && ./vmzx -c -o - -a basic.z80 program.tap | $(FF1) - $(FF2) program.mp4 2>/dev/null

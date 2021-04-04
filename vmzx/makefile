all:
	g++ `sdl-config --cflags --libs` main.cc -lSDL -o vmzx
	./vmzx

dizzy3:
	./vmzx dizzy3.z80
tap:
	./vmzx basic.z80 program.tap
png:
	./vmzx dizzy3.z80 -o record.png
	ffmpeg -framerate 50 -r 50 -i record.png -f mp4 -q:v 0 -vcodec mpeg4 -y record.mp4
mp4:
	./vmzx dizzy3.z80 -o - | ffmpeg -framerate 50 -r 50 -i - -f mp4 -q:v 0 -vcodec mpeg4 -y record.mp4

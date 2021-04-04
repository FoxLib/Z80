all:
	g++ `sdl-config --cflags --libs` main.cc -lSDL -o main
	#./main
	./main dizzy3.z80 -o record.png
png:
	ffmpeg -framerate 50 -r 50 -i record.png -f mp4 -q:v 0 -vcodec mpeg4 -y record.mp4

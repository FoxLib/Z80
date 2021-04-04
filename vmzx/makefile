FF1=ffmpeg -framerate 50 -r 50 -i
FF2=-f mp4 -q:v 0 -vcodec mpeg4 -y
SCALE=-vf "scale=w=1280:h=960,pad=width=1920:height=1080:x=320:y=60:color=black" -sws_flags neighbor -sws_dither none

all:
	g++ `sdl-config --cflags --libs` main.cc -lSDL -o vmzx
	./vmzx
nosdl:
	g++ -DNO_SDL main.cc -o vmzx
tap:
	./vmzx basic.z80 program.tap
dizzy3:
	./vmzx dizzy3.z80
dizzy3png:
	./vmzx dizzy3.z80 -o record.png
	make png2mp4
png2mp4:
	$(FF1) record.png $(FF2) record.mp4
mp4:
	./vmzx dizzy3.z80 -o - | $(FF1) - $(SCALE) $(FF2) record.mp4

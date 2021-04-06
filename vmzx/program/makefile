NAME=01_hello
FF1=ffmpeg -framerate 50 -r 50 -i
FF2=-f mp4 -q:v 0 -vcodec mpeg4 -y
B2T=./../bas2tap/bas2tap
SCALE=-vf "scale=w=1280:h=960,pad=width=1920:height=1080:x=320:y=60:color=black" -sws_flags neighbor -sws_dither none

all:
	$(B2T) -q $(NAME).bas ../program.tap
	cd .. && ./vmzx -a basic.z80 program.tap
video:
	$(B2T) -q $(NAME).bas ../program.tap
	# $(FF1) - $(SCALE) $(FF2) program.mp4 2>/dev/null
	cd .. && ./vmzx -c -o - -M 10 -a basic.z80 program.tap | $(FF1) - $(FF2) program.mp4 2>/dev/null

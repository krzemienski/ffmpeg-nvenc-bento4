# ffmpeg-nvenc-bento4



docker build -t ffmpeg-nvenc-bento4:latest .

docker run --runtime=nvidia -ti -i /patch/to/input.mov:/data ffmpeg-nvenc-bento4  ffmpeg -y -i bbc-hdr-test-asset.mov -hwaccel cuvid -b:v 18000000 -pass 1 \
-pix_fmt yuv420p10le \
-color_primaries 9 -color_trc 16 -colorspace 9 -color_range 1 \
  -maxrate 26800000 -minrate 8040000 -profile:v main10 -vcodec libx265 -f mp4 /dev/null && \
   ffmpeg -i /patch/to/input.mov -b:v 18000000 -pass 2 \
   -pix_fmt yuv420p10le \
   -color_primaries 9 -color_trc 16 -colorspace 9 -color_range 1 \
   -maxrate 26800000 -minrate 8040000 -profile:v main10 -vcodec libx265 \
   hdr-test.mp4
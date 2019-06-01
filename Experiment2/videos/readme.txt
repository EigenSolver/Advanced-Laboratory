The cmd.bat is a shellscrpit to compress the video (it's too large).

cmd: 
ffmpeg -i "obj.mp4" -pix_fmt gray -r 5 -s 720x1280  "obj.avi"

The original video is mp4 format with 1080P 60fps in rgb32 color.
It's converted to to avi format with 720P 5fps in grayscale color.
import imageio

# I haven't tested this yet.  It is based on:
# https://www.youtube.com/watch?v=Uv25CLHuNHU


# Files for frames
#
# To double the duration of a frame,
# try including it twice
filenames = []

outfile_name = ""
seconds_per_frame = 1



images = []
for filename in filenames:
	images.append(imageio.imread(filename))


imageio.mimsave(outfile_name, images, "GIF", duration=seconds_per_frame)


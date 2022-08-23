import PyPDF2
import pyttsx3

# I haven't tested this yet.  This is based on:
# https://www.youtube.com/watch?v=Uv25CLHuNHU


# Set these to appropriate values
filename = ""
out_filename = ""



pdf_reader = PyPDF2.PdfFileReader(open(filename, 'rb'))
engine = pyttsx3.init()

full_text = []

for page_num in range(pdf_reader.numPages):
	full_text.append(pdf_reader.getPage(page_num).extractText())


# Uncomment the following and comment the save_to_file
# lines, to speak out loud instead of saving to a file.

#for text in full_text:
#	engine.say(text)
#	engine.runAndWait()


# Generate the audio and save to file
engine.save_to_file(" ".join(full_text), out_filename)
engine.runAndWait()


engine.stop()


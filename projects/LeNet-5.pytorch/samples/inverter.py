from PIL import Image
import PIL.ImageOps
import sys, getopt

def invert(images):
    inverted_images = PIL.ImageOps.invert(images)
    return inverted_images

if __name__=='__main__':
    imag = Image.open(sys.argv[1])
    base = os.path.splittext(imag)[0]
    print("imag=", imag, "base=", base);
    inv_imag = invert(imag)
    inv_imag.save('invered.png')

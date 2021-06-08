import fitz
import os

def topng(path, directory):
    print(path)

    doc = fitz.open(path)

    dpi = 300
    name = path.split("\\")[-1]
    name_without_ext = name[:-4]
    os.chdir(directory+"\\Building Plans\\PNGS") #cant save to any directory, has to be working

    for i, p in enumerate(doc):
        page = doc.loadPage(i)  # number of page
        pix = page.getPixmap(matrix=fitz.Matrix(dpi/72,dpi/72))
        pix.setResolution(dpi, dpi)
        output = name_without_ext + "_" + str(i) + ".png"
        print(output)
        pix.writePNG(output)

directory = os.path.dirname(os.path.realpath(__file__)) # gets directory
for building in os.scandir(directory + r"\Building Plans"):
    if building.path[-3:] == "pdf":
        topng(building.path, directory)
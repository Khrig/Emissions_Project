import fitz
import os

def topng(path):
    print(path)
    fail_list = []
    try:
        doc = fitz.open(path)
    except: 
        return [path]
    dpi = 300
    pathtrim = path[1:-4]
    name = pathtrim.split("\\")[-1]
    

    for i, p in enumerate(doc):
        try:
            page = doc.loadPage(i)  # number of page
            pix = page.getPixmap(matrix=fitz.Matrix(dpi/72,dpi/72))
            pix.setResolution(dpi, dpi)
            output = name + "_" + str(i) + ".png"
            print(output)
            pix.writePNG(output)
        except:
            fail_list.append(output)
    return fail_list


directory = r"C:\Users\rawdo\Documents\year 4\project\Building Plans Full"
all_fails = []
for building in os.scandir(directory):
    all_fails = all_fails + topng(building.path)
print(len(all_fails), " failure(s); ",all_fails)
    
        

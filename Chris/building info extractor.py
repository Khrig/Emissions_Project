import cv2
import pandas as pd
import numpy as np
import os
import re
import pytesseract
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract'

def main():
    directory = r"C:\Users\rawdo\Documents\year 4\project\Building Plans Full\PNG"
    paths  = [page.path for page in os.scandir(directory)]
    all_meta_data = []
    for path in paths:
        floor_meta_data = {'path': path} #add path to start as unique identifier
        page = cv2.imread(path)
        page_binary = pre_process(page)
        box_contours = find_info_contours(page_binary, page)

        for cnt in box_contours: # for each info-box
            x, y, w, h = cv2.boundingRect(cnt) 
            info_box = page[y:y + h, x:x + w] #obtain info_box as seperate image
            d = pytesseract.image_to_string(info_box, config = '--psm 3')
            d = d.strip('\n\x0c ') #strip out whitespace and newline
            info_type, info_value = find_info(d)
            if info_value != "":
                floor_meta_data[info_type] = info_value

        all_meta_data.append(floor_meta_data)
    m_d_frame = pd.DataFrame(all_meta_data)
    for each in ["AI", "Al"]:
        m_d_frame["paper size"][m_d_frame["paper size"] == each] = "A1"
    #print(m_d_frame)
    path = directory + "\\Floor_Plan_Metadata.csv"
    m_d_frame.to_csv(path)

def find_info(d): #finds the type and value of information in each box
    match_list = ['building name', 'building number', 'drawing number', 'drawing title', 'scale', 'paper size']
    for m in match_list:
        if re.search(m, d, flags = re.I):
            if m == "scale":    #special case for scale because it contains a colon
                print(d)
                val = d.split(" ")[-1]
                print(val)
                val = convert_scale(val)
                print(val)
            else:
                val = d.split(":")[-1]
                if val[0] == " ": # trim space if exists
                    val = val[1:] 
            return m, val # return what the match was and what the value was
    return "","" #return empty if no matches        

def pre_process(page):
    gray=cv2.cvtColor(page,cv2.COLOR_BGR2GRAY) 
    gray=255-gray
    binary_page = cv2.threshold(gray,1,255,cv2.THRESH_BINARY)[1]
    return binary_page

def find_info_contours(binary_page, page):
    contours, hierarchy = cv2.findContours(binary_page, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
    hierarchy = hierarchy[0] #weird opencv returns contours, [hierarchy].
    cnts = list(zip(contours, hierarchy)) #=[[cnt1,hier1],[cnt2,hier2],[cntn,hiern]]
    biggest = max(cnts, key = lambda k: cv2.contourArea(k[0])) #biggest cntour 

    def layer_maker(cnts, cnt):#constructs a layer from the first child of that layer.
        cur = cnt[-1]
        next_index = cur[1][0]
        if next_index != -1:
            cnt.append(cnts[next_index])
            layer_maker(cnts, cnt)
        return(cnt)

    layer = layer_maker(cnts, [biggest])
    
    n = 1 #number of layers to go down
    for i in range(n):
        layer.sort(key = lambda k: cv2.contourArea(k[0]))
        last = layer[-1]
        nextCnt = cnts[last[1][2]]
        layer = layer_maker(cnts, [nextCnt])
        
    #***uncomment for making diagrams***
    # for c in layer[0:-1]:
    #     col = list(np.random.random(size=3) * 200)
    #     cv2.drawContours(page,[c[0]],0,col,10) 
    # resized = cv2.resize(page, (1800,950))
    # cv2.imshow('page', resized)
    # cv2.waitKey()
    #cv2.imwrite(r"C:\Users\rawdo\Documents\year 4\project\meta_contours.PNG", page)

    layer.sort(key = lambda k: cv2.contourArea(k[0]))
    
    box_contours = [cntList[0] for cntList in layer[0:-1]]
    return box_contours

def convert_scale(scale):# turns scale from e.g. 1:100 to 0.01
    if scale != "NTS":
        try:
            scale = 1/int(scale.split(":")[-1])
        except:
            scale = -1
    return scale
main()
print("Done")
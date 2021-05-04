import cv2
import pandas as pd
import numpy as np
import os
import re
import pytesseract
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract'

def main():
    directory = r"C:\Users\rawdo\Documents\year 4\project\Building Plans Full\PNG"
    CSVPath = r"C:\Users\rawdo\Documents\year 4\project\all_building_areas1.3.csv"
    paths  = [page.path for page in os.scandir(directory)]
    data = pd.read_csv(CSVPath)
    all_nuggets = []
    for path in paths:
        nuggets = {'path': path}
        page = cv2.imread(path)
        page_binary = pre_process(page)
        info_contour = find_info_contour(page_binary)
        for cnt in info_contour:
            x, y, w, h = cv2.boundingRect(cnt)
            page_cnt = page[y:y + h, x:x + w]
            d = pytesseract.image_to_string(page_cnt, config = '--psm 3')
            d = d.strip('\n\x0c ')
            info_nugget = find_info(d)
            if info_nugget != None:
                nuggets[info_nugget[0]] = info_nugget[1]
        
        print(nuggets)

        # cv2.drawContours(page, info_contour, -1, [255,255,255], -1)
        # resized = cv2.resize(page, (1920,1080))
        # cv2.imshow('page', resized)
        # cv2.waitKey()
        all_nuggets.append(nuggets)
    nugget_frame = pd.DataFrame(all_nuggets)
    print(nugget_frame)
    path = directory + "\\Floor_Plan_Metadata.csv"
    nugget_frame.to_csv(path)

def find_info(d):
        match_list = ['building name', 'building number', 'drawing number', 'drawing title', 'scale', 'paper size']
        for m in match_list:
            if re.search(m, d, flags = re.I):
                if m == "scale":
                    val = d.split(" ")[-1]
                    val = convert_scale(val)
                else:
                    val = d.split(":")[-1]
                    if val[0] == " ":
                        val = val[1:] 
                return m, val
        

def pre_process(page):
    gray=cv2.cvtColor(page,cv2.COLOR_BGR2GRAY) 
    gray=255-gray
    kernel = np.ones((5,5),np.uint8)
    pageBinary = cv2.threshold(gray,1,255,cv2.THRESH_BINARY)[1]
    return pageBinary

def find_info_contour(pageBinary):

    contourimg = np.zeros_like(pageBinary)
    contours, hierarchy = cv2.findContours(pageBinary, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
    hierarchy = hierarchy[0]
    cnts = list(zip(contours, hierarchy))
    for cnt in cnts:
        if cnt[1][3] < 0:
            biggest = cnt
            break
    
    def layer_maker(cnts, cnt):
        cur = cnt[-1]
        nextIndex = cur[1][0]
        if nextIndex != -1:
            cnt.append(cnts[nextIndex])
            layer_maker(cnts, cnt)
        return(cnt)

    layer = layer_maker(cnts, [biggest])

    for i in range(1):
         layer.sort(key = lambda k: cv2.contourArea(k[0]))
         last = layer[-1]
         nextCnt = cnts[last[1][2]]
         layer = layer_maker(cnts, [nextCnt])

    layer.sort(key = lambda k: cv2.contourArea(k[0]))
    
    buildingContours = [cntList[0] for cntList in layer[0:-2]]
    return buildingContours

def convert_scale(scale):# turns scale from e.g. 1:100 to 0.01
    if scale != "NTS":
        try:
            scale = 1/scale.split(":")[-1]
        except:
            scale = -1
    return scale
main()

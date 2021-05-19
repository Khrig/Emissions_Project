import re
from PIL import Image
import numpy as np
import pandas as pd
import cv2
import pytesseract
import os

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract'

def main():
    directory = r"C:\Users\rawdo\Documents\year 4\project\Building Plans Full\PNG"
    buildDr = r"C:\Users\rawdo\Documents\year 4\project\Building Plans\County Main MC010.pdf"
    meta_CSV_path = r"C:\Users\rawdo\Documents\year 4\project\Building Plans Full\Floor_Plan_Metadata.csv"
    buildingDFs = []
    buildings = []
    paths  = [page.path for page in os.scandir(directory)]

    m_data = pd.read_csv(meta_CSV_path, index_col = 0)
    print(m_data)
    def sorter(path):
        split1 = path.split("_")[-1]
        split2 = split1.split(".")[0]
        return int(split2)

    for path in paths:
        if path[-5] == "0" and path[-6] == "_":
            buildings.append([])
        buildings[-1].append(path)

    for building in buildings:
        orderedBuilding = building
        orderedBuilding.sort(key = sorter)
        print(orderedBuilding)
        floorDFs = [process(floor) for floor in orderedBuilding]
        
        buildingDF = pd.concat(floorDFs, ignore_index = True)
        buildingDFs.append(buildingDF)

    m_data["name"] = m_data["path"].str.split("\\").str[-1].str.split(".").str[0] #takes the paths and strips off the path part leaving floor name
    allDFs = pd.concat(buildingDFs, ignore_index = True)
    allDFs["name"] = allDFs["PNG_title"].str.split("\\").str[-1].str.split(".").str[0]
    allDFs = pd.merge(m_data, allDFs, on = "name")
    allDFs.drop(columns = ["name", "path"])

    allDFs.to_csv('all_building_areas1.4.csv')
    #buildingDF = post_process(buildingDF)

    # with pd.ExcelWriter('room_areas.xlsx') as writer:
    #    for i, DF in enumerate(buildingDFs):
    #        sheetname =DF.at[0, "building_name"]
    #        print(DF)
    #        print("sheetname =", sheetname)
    #        DF.to_excel(writer, sheet_name = sheetname) 
    #    writer.save()

def trim_path(path):
    name_and_file_ext = path.split("\\")[-1]
    name = name_and_file_ext.split(".")[0]
    return name

def process(path):
    page = cv2.imread(path)
    arrayPage = np.asarray(page)

    pageGray = pre_process(arrayPage)
    #pageGray.save('out.png', 'png')

    d = pytesseract.image_to_data(pageGray, config = '--psm 11 load_system_dawg=False load_freq_dawg=False',  output_type = pytesseract.Output.DICT)

    dTemp = {}

    for key in d:
        dTemp[key] = [d[key][i] for i, text in enumerate(d['text']) if text != '']
    d = dTemp
    print(d['text'])
    r = find_room_names(d)
    pageDF = pd.DataFrame(r)
    pageDF['PNG_title'] = path
    print(pageDF)
    return(pageDF)

def pre_process(img):
    gray=cv2.cvtColor(img,cv2.COLOR_BGR2GRAY) 
    gray=255-gray
    page_binary = cv2.threshold(gray,1,255,cv2.THRESH_BINARY)[1]
    inner_page_cnt = find_info_contour(page_binary)

    mask = np.zeros_like(img)
    cv2.fillPoly(mask, [inner_page_cnt], [255,255,255])

    white = cv2.bitwise_not(mask)
    inner_page = cv2.bitwise_and(mask,img)

    img = cv2.add(white, inner_page)
    
    x, y, w, h = cv2.boundingRect(inner_page_cnt)
    inner_page = img[y:y + h, x:x + w]

    # resize = cv2.resize(inner_page, (1920, 1080))
    # cv2.imshow("resize", resize)
    # cv2.waitKey()

    kernel = cv2.getStructuringElement(cv2.MORPH_RECT,(3,3))
    inner_page = cv2.cvtColor(inner_page,cv2.COLOR_BGR2GRAY)
    thresh, inner_page = cv2.threshold(inner_page, 90, 255, cv2.THRESH_BINARY)
    inv = cv2.bitwise_not(inner_page)
    inv = cv2.morphologyEx(inv, cv2.MORPH_CLOSE, kernel)
    #img = cv2.morphologyEx(img, cv2.MORPH_OPEN, kernel)
    inner_page = cv2.bitwise_not(inv)

    inner_page = cv2.GaussianBlur(inner_page,(3,3),0)
    cv2.imwrite(r"C:\Users\rawdo\Documents\year 4\project\outinnerpage.PNG", inner_page)
    return inner_page

def find_info_contour(page_binary):

    contourimg = np.zeros_like(page_binary)
    contours, hierarchy = cv2.findContours(page_binary, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
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
    
    buildingContours = layer[-1][0]
    return buildingContours

def find_right(iList, d):
    currentI = iList[-1]
    width = d['width'][currentI]
    height = d['height'][currentI]
    left = d['left'][currentI]
    top = d['top'][currentI]
    k = 1
    y = 0.1

    for i, val in enumerate(d['top']):
        text = d['text'][i]
        isText = text != '' and text != d['text'][currentI] 
        isNotOld = i != currentI
        if top - int(height*y) < val <  top + int(height*y) and isText and isNotOld:
            if left + int(width + k*height) > d['left'][i] and d['left'][i] > left:
                
                iList.append(i)
                find_right(iList, d)

    return(iList)        

def find_room_names(d):
    r = {'room_name': [], 'room_desc': [], 'room_area': []}
    if len(d["text"]) == 0:
        return r
    areaIndices = []
    wordCount = len(d['text'])
    pattern = re.compile(r'[0-9]+\.[0-9]+m')
    pattern2 = re.compile(r'[0-9]+m\?')

    for i, word in enumerate(d['text']):
        match = pattern.search(word)
        if match:
            area = match.group(0)[:-1]

        else :
            match = pattern2.search(word)
            if match:
                area = match.group(0)[:-2] + ".0"
        
        if match :  #finds the area text '[0-9]+\.[0-9]+m'
            areaIndices.append(i)
            left = d['left'][i]
            width = d['width'][i]
            top = d['top'][i]
            height = d['height'][i]

            maxLeft = left - height*2
            maxRight = left + height*2
            maxSpacing = height*4
             
            closeIndex = [d for d in range(i-int(wordCount/5), i)] #dont need to search whole list
            closeIndex.sort(reverse = True, key = lambda k: d['top'][k])
            #print("closeIndextext=", [d['text'][item] for item in closeIndex])
            txts = [d['text'][index] for index in closeIndex]
            aboveList = []      #this should be recursive probably
            n = 0
            for index in closeIndex:
                txt = d['text'][index]
                isCloseX = maxLeft <= d['left'][index] <= maxRight       #makes a list of words above the area text
                isText = d['text'][index] != '' and d['text'][index] != d['text'][i]

                if len(aboveList) == 0:
                    isAbove = top - maxSpacing < d['top'][index] < top
                else:
                    isAbove =  d['top'][aboveList[n-1]] - maxSpacing < d['top'][index] < d['top'][aboveList[n-1]]   #true when current top is less than top but within maxspacing

                if isCloseX and isText and isAbove:
                    aboveList.append(index)
                    n+=1

            #print("abovelist = ", aboveList)
            #print([d['text'][item] for item in aboveList])

            desc, name = return_desc_name(aboveList, d)
            r['room_name'].append(name)
            r['room_desc'].append(desc)
            r['room_area'].append(area)
            print(name, desc, area)
    return(r)    

def return_desc_name(aboveList, d):
    IDpattern = re.compile(r'[A-Za-z]+[0-9]+')

    desc = ''
    name = ''
    length = len(aboveList)

    for _ in range(length):
        closest = max(aboveList, key = lambda k: d['top'][k])
        closestText = d['text'][closest]
        #print('closestText', closestText)
        IDmatch = IDpattern.search(closestText)
        if IDmatch:
            name = closestText
            #print('name =',name)
            break
        else:
            iList = find_right([closest], d)
            closestText = [d['text'][i] for i in iList]
            closestText = " ".join(closestText)
            desc = closestText + " " + desc

        #print('closest = ', closest)
        aboveList.remove(closest)
        #print(aboveList)
    return(desc, name)

#def post_process(DF):
    #Q o0 Aa Ww etc ]]|\
   # DF.room_desc.str.replace(r'[\[\]\\\|\}\{\_\=\@\~\#\:\;\?\>\<\!\£\$\%\^\&\*\(\)]', "", regex = True )

   # return DF

main()
print('done')
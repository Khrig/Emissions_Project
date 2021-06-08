import re
from PIL import Image
import numpy as np
import pandas as pd
import cv2
import pytesseract
import os

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract'

def main():
    cur_dir = os.path.dirname(os.path.realpath(__file__)) # gets directory

    single_building = False
    directory = cur_dir + "\\Building Plans\\PNGs"
    buildDir = cur_dir + "\\Building Plans\\PNGs\\George Fox MC078_1.PNG" # single building to use if single_building == True
    meta_CSV_path = cur_dir + "\\results\\Floor_Plan_Metadata.csv"
    buildingDFs = []
    buildings = []

    if single_building == True: # for easier debugging
        DF = process(buildDir, single_building)
        print(DF)
        return
    else:
        paths  = [page.path for page in os.scandir(directory)]

    m_data = pd.read_csv(meta_CSV_path, index_col = 0)
    def path_sorter(path):
        split1 = path.split("_")[-1]
        split2 = split1.split(".")[0]
        return int(split2)

    for path in paths:
        if path[-5] == "0" and path[-6] == "_":
            buildings.append([])
        buildings[-1].append(path)

    for building in buildings:
        ordered_building = building
        ordered_building.sort(key = path_sorter)
        print(ordered_building)
        floorDFs = [process(floor, single_building) for floor in ordered_building]
        
        buildingDF = pd.concat(floorDFs, ignore_index = True)
        buildingDFs.append(buildingDF)

    m_data["name"] = m_data["path"].str.split("\\").str[-1].str.split(".").str[0] #takes the paths and strips off the path part leaving floor name
    allDFs = pd.concat(buildingDFs, ignore_index = True)
    allDFs["name"] = allDFs["PNG_title"].str.split("\\").str[-1].str.split(".").str[0]
    allDFs = pd.merge(m_data, allDFs, on = "name")
    allDFs.drop(columns = ["name", "path"])

    allDFs.to_csv(cur_dir + '\\results\\all_building_areas1.5.csv')

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

def process(path, single_building):
    page = cv2.imread(path)
    page_array = np.asarray(page)
    page_gray, displacement = pre_process(page_array)
    #page_gray.save('out.png', 'png')

    d = pytesseract.image_to_data(page_gray, config = '--psm 11 load_system_dawg=False load_freq_dawg=False',  output_type = pytesseract.Output.DICT)

    dTemp = {}

    for key in d:
        dTemp[key] = [d[key][i] for i, text in enumerate(d['text']) if text != '']#removing whitespace in d
    d = dTemp
    print(d)
    print(d['text'])
    r = find_room_areas(d)
    #convert desc,name,area locations back to full size
    r = convert_boxes(r, displacement)
    if single_building:
        draw_boxes(page, r, path)
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
    displacement = (x,y)
    inner_page = img[y:y + h, x:x + w]

    inner_page = cv2.cvtColor(inner_page,cv2.COLOR_BGR2GRAY)
    thresh, inner_page = cv2.threshold(inner_page, 90, 255, cv2.THRESH_BINARY)

    inner_page = cv2.GaussianBlur(inner_page,(3,3),0)
    return inner_page, displacement

def find_info_contour(page_binary):
    contours, hierarchy = cv2.findContours(page_binary, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
    hierarchy = hierarchy[0]
    cnts = list(zip(contours, hierarchy))
    biggest = max(cnts, key = lambda k: cv2.contourArea(k[0])) #biggest cntour 

    def layer_maker(cnts, cnt):
        cur = cnt[-1]
        next_index = cur[1][0]
        if next_index != -1:
            cnt.append(cnts[next_index])
            layer_maker(cnts, cnt)
        return(cnt)

    layer = layer_maker(cnts, [biggest])

    for i in range(1):
         layer.sort(key = lambda k: cv2.contourArea(k[0]))
         last = layer[-1]
         next_cnt = cnts[last[1][2]]
         layer = layer_maker(cnts, [next_cnt])

    layer.sort(key = lambda k: cv2.contourArea(k[0]))
    
    building_contours = layer[-1][0]
    return building_contours

def find_room_areas(d):
    r = {'room_name': [], 'room_desc': [], 'room_area': [], 'desc_loc_lists': [], 'name_locs': [], 'area_locs': []}
    if len(d["text"]) == 0:
        return r
    area_indices = []
    word_count = len(d['text'])
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
            area_indices.append(i)
            left = d['left'][i]
            width = d['width'][i]
            top = d['top'][i]
            height = d['height'][i]

            max_left = left - height*2
            max_right = left + height*2
            max_spacing = height*4
             
            close_indices = [d for d in range(i-int(word_count/5), i)] #dont need to search whole list
            close_indices.sort(reverse = True, key = lambda k: d['top'][k]) # sort by height, lowest first
            above_list = []     
            n = 0
            for index in close_indices:
                is_close_x = max_left <= d['left'][index] <= max_right       #True if close in x
                is_text = d['text'][index] != '' and d['text'][index] != d['text'][i] # true if not empty or equal to current candidate

                if len(above_list) == 0:
                    is_above = (top - max_spacing) < d['top'][index] < top
                else:
                    is_above =  (d['top'][above_list[n-1]] - max_spacing) < d['top'][index] < d['top'][above_list[n-1]]   #true when current top is less than top but within maxspacing

                if is_close_x and is_text and is_above:
                    above_list.append(index)
                    n+=1

            #print("abovelist = ", above_list)
            #print([d['text'][item] for item in above_list])

            desc, name, desc_locs, name_loc = find_desc_name(above_list, d)
            area_loc = make_loc_dict(d, i)
            r['area_locs'].append(area_loc)
            r['name_locs'].append(name_loc)
            r['desc_loc_lists'].append(desc_locs)
            r['room_name'].append(name)
            r['room_desc'].append(desc)
            r['room_area'].append(area)
            print(name, desc, area)
    return(r)    

def find_desc_name(above_list, d):
    IDpattern = re.compile(r'[A-Za-z]+[0-9]+')

    desc = ''
    name = '' #return empty if none found
    desc_locs = []
    name_loc = {}

    length = len(above_list)
    desc_locs = []
    for _ in range(length):
        closest = max(above_list, key = lambda k: d['top'][k])
        closest_text = d['text'][closest]
        IDmatch = IDpattern.search(closest_text)
        if IDmatch:
            name = closest_text
            name_loc = make_loc_dict(d,closest)
            break
        else:
            desc = closest_text + " " + desc
            desc_locs.append(make_loc_dict(d, closest))
        above_list.remove(closest)
    return (desc, name, desc_locs, name_loc)

def make_loc_dict(d,i):
    loc_d = {}
    loc_d["y1"] = d["top"][i]
    loc_d["x1"] = d["left"][i]
    loc_d["y2"] = d["top"][i] + d["height"][i]
    loc_d["x2"] = d["left"][i] + d["width"][i]
    return loc_d

def convert_boxes(r, displacement):
    keys = ["area_locs", "name_locs"]
    for key in keys:
        for i, loc in enumerate(r[key]):
            if loc == {}:
                continue
            r[key][i]["x1"] = loc["x1"] + displacement[0]
            r[key][i]["x2"] = loc["x2"] + displacement[0]
            r[key][i]["y1"] = loc["y1"] + displacement[1]
            r[key][i]["y2"] = loc["y2"] + displacement[1]
    for i1, list in enumerate(r["desc_loc_lists"]):
        for i2, loc in enumerate(list):
            if loc == {}:
                continue
            r["desc_loc_lists"][i1][i2]["x1"] = loc["x1"] + displacement[0]
            r["desc_loc_lists"][i1][i2]["x2"] = loc["x2"] + displacement[0]
            r["desc_loc_lists"][i1][i2]["y1"] = loc["y1"] + displacement[1]
            r["desc_loc_lists"][i1][i2]["y2"] = loc["y2"] + displacement[1]
    return r


def draw_boxes(page,r,path):
    col_area = [0,0,200]
    col_desc = [0,200,0]
    col_name = [200,0,0]

    for loc in r["area_locs"]:
        cv2.rectangle(page, (loc["x1"], loc["y1"]), (loc["x2"], loc["y2"]), col_area, 5 )
    for loc in r["name_locs"]:
        try:
            cv2.rectangle(page, (loc["x1"], loc["y1"]), (loc["x2"], loc["y2"]), col_name, 5 )
        except:
            continue

    for list in r["desc_loc_lists"]:
        for loc in list:
            try:
                cv2.rectangle(page, (loc["x1"], loc["y1"]), (loc["x2"], loc["y2"]), col_desc, 5 )
            except:
                continue
    #cv2.imwrite(r"C:\Users\rawdo\Documents\year 4\project\boxed_text.PNG", page) # use for writing text boxed images
    resized = cv2.resize(page, (1800,950))
    cv2.imshow('page', resized)
    cv2.waitKey()

main()
print('done')
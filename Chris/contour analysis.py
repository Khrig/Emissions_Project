import cv2
import pandas as pd
import numpy as np
import os

def main():
    directory = r"C:\Users\rawdo\Documents\year 4\project\Building Plans\campus\PNGs"
    CSVPath = r"C:\Users\rawdo\Documents\year 4\project\all_building_areas1.4_GF_CORRECTED.csv"
    scale_path = r"C:\Users\rawdo\Documents\year 4\project\manual scale.CSV"
    
    data = pd.read_csv(CSVPath)
    manual_scale = pd.read_csv(scale_path)

    airAreas = data.groupby(["PNG_title"], as_index = True )["room_area"].sum()

    f_df = data.drop_duplicates("PNG_title")
    f_df = f_df.set_index("PNG_title")
    f_df = f_df.drop(columns = ["room_name", "room_desc", "room_area", "path", "drawing number"])
    f_df["area_air"] = airAreas
    print(manual_scale)
    print(f_df.at[r"C:\Users\rawdo\Documents\year 4\project\Building Plans Full\PNG\George Fox MC078_0.png", "scale"])

    for i, path in enumerate(manual_scale["path"]): #changes the scale for buildings with the wrong scale in the plan
        manual_scale_val = manual_scale["scale"].iloc[i]
        f_df.at[f_df.index == path, "scale"] = manual_scale_val
    print(f_df.index)
    print(f_df.at[r"C:\Users\rawdo\Documents\year 4\project\Building Plans Full\PNG\George Fox MC078_0.png", "scale"])
    #    f_df["scale"].iloc[f_df.index.get_loc(path)] = manual_scale["scale"][manual_scale["path"] == path]
   
    #could do with putting this in a file, especially for more buildings
    heights = {"MC052":11.9, "MC064":15.47, "MC062":40.1, "MC029":8.03, "MC010":13.7, "MC031":10.44, "MC047":2.95, "MC078":15.1}
    roof_height = 0.3
    
    imgList = [img.path for img in os.scandir(directory) if img.path[-3:] != "csv"]
    perimList = []
    areaList = []
    disp_paths = ["George Fox MC078_0"] # put buildings that you want to be dsiplayed in here in format "PNG name"_"floor number"

    for path in f_df.index:
        modifiedPath = directory + "\\" + path.split("\\")[-1]#original images were in a different directory
        if modifiedPath in imgList:
            page = cv2.imread(modifiedPath)
        else:
            areaList.append(0)
            perimList.append(0)
            continue

        size = f_df.at[path, "paper size"]
        scale = f_df.at[path, "scale"]

        if path.split("\\")[-1].split(".")[0] in disp_paths:
            disp = True
        else:
            disp = False

        pixArea, pixPerimeter = process(page, disp)
        print(path)
        print(pixArea, pixPerimeter)
        mpp = pixel_to_meter(page, scale, size) #meters per pixel
        print(mpp)
        area = pixArea*mpp*mpp
        perimeter = pixPerimeter*mpp
        
        areaList.append(area)
        perimList.append(perimeter)
        print("perimeter =", perimeter, "area = ", area)

    f_df["perimeter"] = perimList
    f_df["area_total"] = areaList

    f_df["area_wall"] = f_df["area_total"]-f_df["area_air"]
    f_df.loc[f_df["area_wall"] < 0, "area_wall"] = 0
    f_df["volume_air"] = 0
    f_df["volume_wall"] = 0
    f_df["surface_area_wall"] = 0
    f_df["surface_area_roof"] = 0

    for name in heights: #for each building we have a height for
        bool_name_list = f_df["building number"] == name 
        floor_count = f_df["building number"].value_counts()[name] #number of floors
        floor_height = (heights[name]/floor_count) - roof_height #height of each floor
        f_df.loc[bool_name_list, "volume_air"] = floor_height * f_df["area_air"][bool_name_list] #air volume in each floor
        roof_volume = roof_height * f_df["area_total"][bool_name_list] #volume of floor, as in what you stand on
        f_df.loc[bool_name_list, "volume_wall"] = floor_height * f_df["area_wall"][bool_name_list] + roof_volume #volume of wall in each floor
        f_df.loc[bool_name_list, "surface_area_wall"] = (floor_height + roof_height) * f_df.loc[bool_name_list, "perimeter"] #external surface area of each floor
        
    for i in range(len(f_df.index)): # finding roof area by comparing above floor area to below floor area
    
        if i+1 >= len(f_df.index):
            f_df["surface_area_roof"].iloc[i] = f_df["area_total"].iloc[i]
        else:
            if f_df["building number"].iloc[i] != f_df["building number"].iloc[i+1]:
                f_df["surface_area_roof"].iloc[i] = f_df["area_total"].iloc[i]
            else:
                f_df["surface_area_roof"].iloc[i] = f_df["area_total"].iloc[i] - f_df["area_total"].iloc[i+1]
        
    f_df.loc[f_df["surface_area_roof"] < 0, "surface_area_roof"] = 0  #removes small negative values from error
    f_df["index"] = [i for i in range(len(f_df.index))]
    f_df = f_df.set_index("index")
    path = directory + "\\floor_volumes1.1.csv"
    f_df.to_csv(path)

def pixel_to_meter(page, scale, size): #figure out pixel scale with image size paper size and scale
    scale = float(scale)
    print("scale = ", scale)
    if scale < 1:
        scale = 1/scale
    print(scale)
    imgSize = page.shape
    paperSizes = {"A0": [841, 1189], "A1": [594, 841], "A2": [420, 594], "A3": [297, 420], "A4": [210, 297]}
    sizex = paperSizes[size][0]/1000

    if imgSize[0] < imgSize[1]: #sorts out orientations, x is always smallest
        imgx = imgSize[0]
    else:
        imgx = imgSize[1]

    mpp = ((sizex*scale)/imgx) #meters per pixel

    return (mpp)

def process(page, disp):
    page_binary = pre_process(page)
    bcs = find_building_contours(page_binary)
    buildingArea = sum([cv2.contourArea(cnt) for cnt in bcs])        
    buildingPerimeter = sum([cv2.arcLength(cnt, True) for cnt in bcs])
    cv2.drawContours(page,bcs,-1,[200,0,200], 20)
    if disp:
        resized = cv2.resize(page, (1620,780))
        cv2.imshow('page', resized)
        cv2.waitKey()
        cv2.imwrite(r"C:\Users\rawdo\Documents\year 4\project\contour_out.PNG", page)
    return buildingArea, buildingPerimeter

def pre_process(page):
    page = cv2.GaussianBlur(page,(3,3),0)
    gray=cv2.cvtColor(page,cv2.COLOR_BGR2GRAY) 
    gray=255-gray
    page_binary = cv2.threshold(gray,1,255,cv2.THRESH_BINARY)[1]
    kernel = np.ones((5,5),np.uint8)
    dilate = cv2.dilate(page_binary, kernel, iterations = 4)
    erode =  cv2.erode(dilate, kernel, iterations = 4)
    return erode

def find_building_contours(page_binary):
    page_blank = np.zeros_like(page_binary)
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

    for i in range(2):
        layer.sort(key = lambda k: cv2.contourArea(k[0]))
        last = layer[-1]
        nextCnt = cnts[last[1][2]]
        layer = layer_maker(cnts, [nextCnt])

    layer.sort(key = lambda k: cv2.contourArea(k[0]))
    max_area = cv2.contourArea(layer[-1][0])
    building_contours = []

    for cnt in layer:
        if cv2.contourArea(cnt[0]) >= max_area*0.6:  #removes small contours e.g. text
            building_contours.append(cnt[0])

    kernel = np.ones((7,7),np.uint8)
    cv2.drawContours(page_blank, building_contours, -1, [255,255,255], -1)
    erode = cv2.erode(page_blank, kernel, iterations = 10)
    dilate = cv2.dilate(erode, kernel, iterations = 10)
    resized = cv2.resize(dilate, (1620,780))
    cv2.imshow('page', resized)
    cv2.waitKey()    
    building_contours, hierarchy = cv2.findContours(dilate, cv2.RETR_LIST , cv2.CHAIN_APPROX_NONE,)
    
    return building_contours    

main()
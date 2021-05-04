import cv2
import pandas as pd
import numpy as np
import os
import re

def main():
    directory = r"C:\Users\rawdo\Documents\year 4\project\Building Plans\campus\PNGs"
    CSVPath = r"C:\Users\rawdo\Documents\year 4\project\all_building_areas1.4_GF_CORRECTED.csv"
    scale_path = r"C:\Users\rawdo\Documents\year 4\project\manual scale.CSV"
    
    buildingDFs = []
    buildings = []
    paths  = [page.path for page in os.scandir(directory)]
    data = pd.read_csv(CSVPath)
    manual_scale = pd.read_csv(scale_path)

    airAreas = data.groupby(["PNG_title"], as_index = True )["room_area"].sum()

    floors = data.drop_duplicates("PNG_title")
    floors = floors.set_index("PNG_title")
    #floors = floors.drop(columns = ["Unnamed: 0", "room_name", "room_desc", "room_area", "drawing_number"])
    floors = floors.drop(columns = ["room_name", "room_desc", "room_area", "path", "drawing number"])
    floors["area_air"] = airAreas
    print(floors.index)
    print(manual_scale["path"])
    print(manual_scale)
    for path in manual_scale["path"]:
        print(floors.index.get_loc(path))
        floors["scale"].iloc[floors.index.get_loc(path)] = manual_scale["scale"][manual_scale["path"] == path]
    
    heights = {"MC052":11.9, "MC064":15.47, "MC062":40.1, "MC029":8.03, "MC010":13.7, "MC031":10.44, "MC047":2.95, "MC078":15.1}
    roofHeight = 0.3
    
    imgList = [img.path for img in os.scandir(directory)]
    perimList = []
    areaList = []
    disp_paths = [] # put paths that you want to look at in here

    for path in floors.index:
        
        modifiedPath = directory + "\\" + path.split("\\")[-1]
        if modifiedPath in imgList:
            page = cv2.imread(modifiedPath)
        else:
            areaList.append(0)
            perimList.append(0)
            continue

        print(path)
        size = floors.at[path, "paper size"]
        scale = floors.at[path, "scale"]

        if path in disp_paths:
            disp = True
        else:
            disp = False

        pixArea, pixPerimeter = process(page, disp)
        print(pixArea, pixPerimeter)
        mpp = pixel_to_meter(page, scale, size)
        print(mpp)
        area = pixArea*mpp*mpp
        perimeter = pixPerimeter*mpp
        
        areaList.append(area)
        perimList.append(perimeter)
        print("perimeter =", perimeter, "area = ", area)

    floors["perimeter"] = perimList
    floors["area_total"] = areaList

    floors["area_wall"] = floors["area_total"]-floors["area_air"]
    floors["area_wall"][floors["area_wall"]<0] = 0
    floors["volume_air"] = 0
    floors["volume_wall"] = 0
    floors["surface_area_wall"] = 0
    floors["surface_area_roof"] = 0
    print(floors)
    for name in heights:
        print(heights)
        floorHeight = heights[name]/floors["building number"].value_counts()[name] - roofHeight
        print(floorHeight)
        print(name )
        floors["volume_air"][floors["building number"] == name]= floorHeight * floors["area_air"][floors["building number"] == name]
        floors["volume_wall"][floors["building number"] == name]= floorHeight * floors["area_wall"][floors["building number"] == name] + roofHeight*floors["area_total"][floors["building number"] == name]
        floors["surface_area_wall"][floors["building number"] == name]= (floorHeight + roofHeight) * perimeter
        


    for i, each in enumerate(floors["area_total"]):
    
        if i+1 >= len(floors.index):
            print(floors.index[i], "i+1 greater than length")

            floors["surface_area_roof"].iloc[i] = floors["area_total"].iloc[i]
        else:
            if floors["building number"].iloc[i] != floors["building number"].iloc[i+1]:
                print(floors.index[i], "next is first floor")
                floors["surface_area_roof"].iloc[i] = floors["area_total"].iloc[i]
            else:
                floors["surface_area_roof"].iloc[i] = floors["area_total"].iloc[i] - floors["area_total"].iloc[i+1]
        

    floors["surface_area_roof"].loc[floors["surface_area_roof"] < 0]= 0  #removes small negative values
    floors["index"] = [i for i in range(len(floors.index))]
    floors = floors.set_index("index")
    path = directory + "\\floor_volumes_1.0.csv"
    floors.to_csv(path)

     
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
    pageBinary = pre_process(page)
    bcs = find_building_contours(pageBinary)
    buildingArea = sum([cv2.contourArea(cnt) for cnt in bcs])        
    buildingPerimeter = sum([cv2.arcLength(cnt, True) for cnt in bcs])
    cv2.drawContours(page,bcs,-1,[0,255,0], 20)
    if disp:
        resized = cv2.resize(page, (1920,1080))
        cv2.imshow('page', resized)
        cv2.waitKey()
    # resized = cv2.resize(pageBinary, (1920,1080))
    # cv2.imshow('page', resized)
    # cv2.waitKey()

    return buildingArea, buildingPerimeter

def pre_process(page):
    page = cv2.GaussianBlur(page,(3,3),0)
    gray=cv2.cvtColor(page,cv2.COLOR_BGR2GRAY) 
    gray=255-gray
    kernel = np.ones((5,5),np.uint8)
    dilate = cv2.dilate(gray, kernel, iterations=4)
    closing = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)
    pageBinary = cv2.threshold(dilate,1,255,cv2.THRESH_BINARY)[1]
    return pageBinary

def find_building_contours(pageBinary):

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

    for i in range(2):
        layer.sort(key = lambda k: cv2.contourArea(k[0]))
        last = layer[-1]
        nextCnt = cnts[last[1][2]]
        layer = layer_maker(cnts, [nextCnt])

    layer.sort(key = lambda k: cv2.contourArea(k[0]))
    
    maxArea = cv2.contourArea(layer[-1][0])
    buildingContours = []

    for cnt in layer:
        if cv2.contourArea(cnt[0]) >= maxArea - maxArea/3:  #removes small contours e.g. text
            buildingContours.append(cnt[0])
        
    return buildingContours
    
def calculate_thermal(d):
    

main()
import cv2
import numpy as np
# extracts true value of wall and air area for county main using manually annotated pictures
def pre_process(page,ext):
    gray=cv2.cvtColor(page,cv2.COLOR_BGR2GRAY) 
    gray=255-gray
    if ext == True:
        pageBinary = cv2.threshold(gray,10,255,cv2.THRESH_BINARY)[1]

        kernel = np.ones((5,5),np.uint8)
        closing = cv2.morphologyEx(pageBinary, cv2.MORPH_CLOSE, kernel)
        resized = cv2.resize(closing, (1920,1080))
        cv2.imshow('page', resized)
        cv2.waitKey()
        out = closing
    else:
        pageBinary = cv2.threshold(gray,60,255,cv2.THRESH_BINARY)[1]
        resized = cv2.resize(pageBinary, (1920,1080))
        cv2.imshow('page', resized)
        cv2.waitKey()
        out = pageBinary

    return out

ext_walls = cv2.imread(r"C:\Users\rawdo\Documents\year 4\project\ext wall.png")
int_walls = cv2.imread(r"C:\Users\rawdo\Documents\year 4\project\int wall.png")

ext_gray = pre_process(ext_walls, True)
ext_wall_contours, hieararchy_ext = cv2.findContours(ext_gray, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
ext_wall_contours.sort(key = lambda k: cv2.contourArea(k))

outside_wall = ext_wall_contours[-1]
inside_wall = ext_wall_contours[0]
area_outside = cv2.contourArea(outside_wall)
area_interior = cv2.contourArea(inside_wall)
print(area_interior, area_outside)
cnts = [outside_wall, inside_wall]

area_total = area_outside - area_interior
cv2.drawContours(ext_walls,cnts,-1,[0,0,0], -1)


int_gray = pre_process(int_walls, False)
cv2.imwrite("county main truth binary.png", int_gray)

int_wall_contours, hierarchy_int = cv2.findContours(int_gray, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
area_room = sum([cv2.contourArea(cnt) for cnt in int_wall_contours])
area_wall = area_total-area_room
print(len(int_wall_contours))
cv2.drawContours(ext_walls,int_wall_contours,-1,[200,0,0], -1)
cv2.imwrite("county main truth.png", ext_walls)
print("wall area= ", area_wall, "air_area =", area_room)
print("percentage wall", 100*(area_wall)/area_total )
resized = cv2.resize(ext_walls, (1920,1080))
cv2.imshow('page', resized)
cv2.waitKey()


#int_wall_contours, hieararchy_int = cv2.findContours(ext_walls, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)








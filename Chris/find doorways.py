import cv2
import numpy as  np

def main():
    img = cv2.imread(r"C:\Users\rawdo\Documents\year 4\project\floor_plan_2.jpg") #path to floorplan image
    resize = cv2.resize(img,(736,606))
    blur = cv2.GaussianBlur(resize,(3,3),0)
    gray=cv2.cvtColor(blur,cv2.COLOR_BGR2GRAY)
    gray=255-gray
    kernel = np.ones((4,4),np.uint8)
    gray = cv2.erode(gray,kernel,iterations = 1)
    gray = cv2.threshold(gray,150,255,cv2.THRESH_BINARY)[1] #some preproccessing to remove noise and get binary image

    contours,hierarchy = cv2.findContours(gray,cv2.RETR_LIST ,cv2.CHAIN_APPROX_NONE )
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < 50:
            cv2.drawContours(gray,[cnt],0,(0,0,0),-1)
            
    skele = np.copy(gray)
    
    kernel = np.array((
            [-1, -1, -1],
            [0, 1, 0],
            [1, 1, 1]), dtype="int")#kernel for skeletonising

    diagKernel = np.array((
            [0, -1, -1],
            [1, 1, -1],
            [0, 1, 0]), dtype="int")#other kernel for skeletonising

    for each in range(10):
        kernels = []
        for n in range(4):
            kernels.append(np.rot90(diagKernel, k = n)) #rotate the above kernels for all directions and then do hitmiss transform
        skele = hitmiss(skele, kernels, -1)

        kernels = []
        for n in range(4):
            kernels.append(np.rot90(kernel, k = n)) 
        skele = hitmiss(skele, kernels, 1)
    
    gaps = match_ends(skele, 100) # match up end points of skeleton to find doorways/windows
    
    gray_doorways = cv2.bitwise_or(gray, gaps)  

    mask = np.where(gaps == 255)
    resize[mask[0], mask[1], :] = [0, 0, 255] # BGR - resize is now an image with doorways coloured red just to display
    
    contourimg = np.zeros_like(resize)
    contours, hierarchy = cv2.findContours(gray_doorways,cv2.RETR_LIST ,cv2.CHAIN_APPROX_NONE)# find room contours
    
    contours = sorted(contours, key=cv2.contourArea)
    contours = contours[:-1]

    for cnt in contours:    # colour in the rooms random colours
        col = list(np.random.random(size=3) * 100)
        cv2.drawContours(contourimg,[cnt],0,col,-1) 

        M = cv2.moments(cnt)    #find middle of rooms and add area label
        if M['m00'] != 0:
            cx = int(M['m10']/M['m00'])  - 20
            cy = int(M['m01']/M['m00'])
            loc = (cx,cy)
            area = cv2.contourArea(cnt)
            txtString = str(area) + "Px"
            font = cv2.FONT_HERSHEY_SIMPLEX
            cv2.putText(contourimg, txtString, loc, font, 0.5, (255,255,255))

    cv2.add(resize,contourimg)

    cv2.imshow('gaps',gaps)# display results
    cv2.waitKey()
    cv2.imshow('gaps',gray)
    cv2.waitKey()
    cv2.imshow('img',resize)
    cv2.waitKey()
    cv2.imshow('contours',contourimg)
    cv2.waitKey()
    cv2.imshow('gray_doorways', gray_doorways)
    cv2.waitKey()
    cv2.imshow('skeleton', skele)
    cv2.waitKey()  

def hitmiss(gray, kernels, n):

    while True:
        grayTemp = np.copy(gray)
        
        for each in kernels:
            hits = cv2.morphologyEx(gray, cv2.MORPH_HITMISS, each)
            gray = cv2.subtract(gray, hits)
            
        comparison = gray == grayTemp
        
        n = n - 1
        
        if comparison.all() or n == 0:
            return gray


def match_ends(gray, maxdist):
    gaps = np.zeros_like(gray)
    
    for direction in [0,1]: #0 along right 1 down
        
        kernelH = (np.array((
                [-1, -1, -1],
                [1, 1, -1],
                [-1, -1, -1]), dtype="int"))
        
        kernelV = np.array((
                [-1, 1, -1],
                [-1, 1, -1],
                [-1, -1, -1]), dtype="int") 
        kernel = (kernelH,kernelV)
        
        hits = cv2.morphologyEx(gray, cv2.MORPH_HITMISS, kernel[direction])
        hitcoords = np.nonzero(hits)
        hitlist = []
        
        for n in range(hitcoords[0].size):
            hitlist.append([hitcoords[0][n],hitcoords[1][n]]) #probs better way to do this, just reformats hitcoords
      
        n=0
        for hit in hitlist:
            
            inirow = hit[0] 
            inicol = hit[1]            
            testMat = np.zeros([3,3], dtype = int)

            found = False
            
            for mod in [0,1,-1,2,-2]: #allows for misaligned endpoints
                
                if found == True: break # go to next point if match has been found
                
                if direction == 0:      # if looking horizontal check rows above and below
                    col = inicol
                    row = inirow + mod
                else:                   #or columns L and R if vertical
                    col = inicol + mod
                    row = inirow
                
                done = False
                dist = 0
                while(not done): #move testMat one pixel per iteration until another endpoint found
                    dist = dist + 1
                    
                    if direction == 0:
                        col = col + 1  #look along columns if direction is horizontal
                    else:
                        row = row + 1  #look along rows if direction is vertical
                    
                    for n in range(3):
                        for x in range(3):
                            testMat[x, n] = 1 if gray[row-1+x,col-1+n] == 255 else -1   #should just get the submatrix but dont know how lol
                    testKernel = np.rot90(kernel[direction], 2)
                    comparison = testMat == testKernel
                    
                    if comparison.all():
                        cv2.line(gaps, (inicol,inirow),(col, row),255,2)
                        done = True
                        found = True

                    elif dist == maxdist or col == len(gray[0]) - 3 or row == len(gray)-3: #stop if max opening distance reached or edge of image reached
                        done = True     
    return(gaps)

main()

        
    
    

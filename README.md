## Repository for fourth year project "Reducing Campus Emissions Using Machine Learning"

# Chris

***

**Requirements:**
in addition to Chris/requirements.txt, tesseract will need to be installed.


**Instructions:**

1. Put pdf versions of plans in Chris/building plans

2. run fitz pdf to image

3. run building info extractor

4. check metadata is ok in /results

5. run text area detect

6. optionally check and correct outputs, copy to building plans corrected.csv. Can see what tesseract has detected by setting single building to true in text area detect, alternatively building plans corrected already has a complete set of results

7. correct plans such that the external contour of the buildings does not intersect with the boxes of the plan and that doughnut shaped buildings have holes in the exterior, as detailed in report.

8. place corrected plans and all other plans to run further steps on in to building plans corrected, alternatively, corrected versions are available on teams.

9. run contour analysis, can check wether the correct contour has been found by adding the buildings name to disp_paths

10. run thermal analysis

11. run model to simulate a building. only working with George Fox at the moment as data is not great for other buildings


Final versions of my results can be found in Chris/results

# Ben

- All code can be opened and run in Google Colab
- Colab Folder: [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://drive.google.com/drive/folders/1u4mqVC7Kauv7FF4X_Y4V6GW9zDt4JrqY?usp=sharing)

## Overiew
This section of the project looks at forecasting thermal energy and occupancy data to allow the energy management team to pre-emptively respond to periods of high energy use and occupancy. The results showed that the low quality data in the thermal energy sensors data was best forecast using statistical techniques such as an ARIMA model whereas the higher quality occupancy data achieved greater accuracy using Deep Learning models, specifically Informer.

## Requirements
python==3.7.10\
pandas==1.1.5\
numpy==1.19.5\
matplotlib==3.2.2\
sklearn==0.0\
tensorflow==2.5.0\
xgboost==0.90\
fbprophet=0.7.1\
pmdarima==1.8.2\
statsmodels==0.12.2
# Katie

# Henry

*...*

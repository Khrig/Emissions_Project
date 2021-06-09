# Forecasting Thermal Energy and Occupancy Data

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
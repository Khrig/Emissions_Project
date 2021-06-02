import math
import matplotlib.pyplot as plt
import numpy as np
from scipy.integrate import odeint
import pandas as pd
data_dir = r"C:\Users\rawdo\Documents\year 4\project\thermal data"
thermal_results_csv_path = r"C:\Users\rawdo\Documents\year 4\project\Thermal Results.csv"
thermDF = pd.read_csv(thermal_results_csv_path, index_col = 0)
building = "George Fox MC078"
data_csv_path = data_dir + "\\" + building + ".csv"
is_data = True
tempDF = pd.read_csv(data_csv_path, index_col = 0, parse_dates = True)
is_data = True
print(tempDF)
start_time = 6
end_time = 9
#tempDF = tempDF[tempDF.index[start_time*12+12*12]:tempDF.index[start_time*12+12*12+(12-start_time)*12+end_time*12]]
tempDF = tempDF[41982:42129]
tempDF = tempDF.resample("S").ffill()
data_series = tempDF["Average"]
data_list = data_series.tolist()
print(data_series)
print(tempDF)

print(tempDF.keys)
print(thermDF)
T_out = 12 + 273
U_wall = thermDF.at[building, "total_UA"]
U_wall_ext = U_wall
U_wall_in = U_wall*7
vent_const = thermDF.at[building, "ventilation_constant"]/1.5
air_cap = thermDF.at[building, "air_cap"]
wall_cap = thermDF.at[building, "wall_cap"]
T_in_initial_air = 21+273
T_in_initial_wall = 20+273
hours_to_sim = 10
t = np.linspace(0,60*60*hours_to_sim, 60*60*hours_to_sim)

if is_data:
    T_in_initial_wall = data_series[0] +273

    T_in_initial_air = data_series[0] +273
    T_out = tempDF["Outside Weather (DegC)"][0] +273
    t = np.linspace(0,len(tempDF.index),len(tempDF.index))
    print(len(t), t[-1])


    

print(U_wall, U_wall_ext, U_wall_in, vent_const, air_cap, wall_cap)

Q_0 = [T_in_initial_wall*wall_cap, T_in_initial_air*air_cap]




def model(Qlist, t, air_cap, wall_cap, U_wall_in, U_wall_ext, t_out_start, k, vent_const):
    print(t)
    #T_out = tempDF["Outside Weather (DegC)"][int(t)] + 273

    T_out = t_out_start + t*k
    Q_wall = Qlist[0]
    Q_air = Qlist[1]
    T_wall = Q_wall/wall_cap
    T_in_air = Q_air/air_cap
    dQ_walldt = U_wall_in * (T_in_air - T_wall) + U_wall_ext * (T_out-T_wall)
    dQ_airdt = U_wall_in * (T_wall-T_in_air) + vent_const * (T_out-T_in_air)
    return [dQ_walldt, dQ_airdt]

t_out_start = tempDF["Outside Weather (DegC)"][0] +273
t_out_fin = tempDF["Outside Weather (DegC)"][-1] +273
k = (t_out_fin-t_out_start)/len(tempDF["Outside Weather (DegC)"])

result = odeint(model, Q_0, t, args = ( air_cap, wall_cap, U_wall_in, U_wall_ext, t_out_start, k, vent_const))
t_hours = t/(60*60)
print(result[:,0]-273)
result_degrees_wall = result[:,0]/wall_cap -273
result_degrees_air = result[:,1]/air_cap -273


    
plt.plot(t_hours, result_degrees_air, label =  'Air Temp')
plt.plot(t_hours, result_degrees_wall, label =  'Wall Temp')
plt.plot(t_hours, data_list, label =  'Data')
plt.title('Cooling Curve')
plt.ylabel('Temperature ($^\circ$C)')
plt.xlabel('Time After Heating Shutdown (Hours)')
plt.legend(loc='best')
plt.show()

import pandas as pd
import os

def conduction(df, u_df, r_df): # find coefficients relating to conduction rate
    window_sa = 0.1 #TEMPORARY
    df["window_area"]=df["surface_area_wall"]*window_sa
    df["surface_area_wall"] = df["surface_area_wall"] - df["window_area"]

    df["roof_UA"] = df["surface_area_roof"]*u_df["roof"]# construct temporary columns in df to multiply
    df["floor_UA"] = df["area_total"]*u_df["floor"]
    df["window_UA"] = df["window_area"]*u_df["window"]
    df["wall_UA"] = df["surface_area_wall"]*u_df["wall"]
    # now assign to r_df, adding up the floors
    r_df["roof_UA"] = df.groupby("name_fp")["roof_UA"].sum() #add up heat loss per dT through roof for each floor
    r_df["wall_UA"] = df.groupby("name_fp")["wall_UA"].sum() #add up heat loss per dT through wall for each floor
    r_df["window_UA"] = df.groupby("name_fp")["window_UA"].sum() #add up heat loss per dT through wall for each floor
    r_df["floor_UA"] = df.groupby("name_fp")["floor_UA"].nth(0) # floor UA is just ground floor
    r_df["total_UA"] = r_df[["roof_UA", "wall_UA", "window_UA", "floor_UA"]].sum(axis = 1)
    return r_df

def ventilation(df, r_df, cp, air_density, u_df): # find coefficients relating to ventiilation rate
    hour = 60*60 # just hour in sec
    roof_area = df.groupby("name_fp")["surface_area_roof"].sum() #adding areas to find total surface area - envelope
    wall_area = df.groupby("name_fp")["surface_area_wall"].sum()
    floor_area = df.groupby("name_fp")["area_total"].nth(0)
    envelope = roof_area + wall_area + floor_area
    print(envelope)
    #multiply max permissible permeability by envelope to get volume of air leaving per sec 
    r_df["ventilation_constant"] = u_df.groupby("name_fp")["permeability"].nth(0).mul(envelope)*cp*air_density/hour
    #divide by hour because permeability is in hours
    return r_df, envelope

def capacity(df, u_df, r_df, cp, air_density, envelope): # find heat capacity of air and walls.
    brick_thickness = 0.1
    df["air_cap_floorwise"] = df["volume_air"]*cp*air_density 
    brick_layer_volume = envelope*brick_thickness
    df["wall_cap_floorwise"] = u_df["spec_wall_heat_cap"].mul(u_df["wall_density"]) #need to times this by volume
    r_df["wall_cap"] = df.groupby("name_fp")["wall_cap_floorwise"].sum().mul(brick_layer_volume)
    r_df["air_cap"] = df.groupby("name_fp")["air_cap_floorwise"].sum() 
    return r_df

def main():
    cur_dir = os.path.dirname(os.path.realpath(__file__)) # gets directory

    U_value_csv_path = cur_dir + "\\results\\U values.csv"
    volume_csv_path = cur_dir + "\\results\\floor_volumes.csv"
    df = pd.read_csv(volume_csv_path, index_col = "index")
    u_df = pd.read_csv(U_value_csv_path) #u values dataframe for heat conduction
    df = df.drop(columns = ["Unnamed: 0", "scale", "paper size", "area_air", "perimeter", "area_wall"])
    df["name_fp"] = df["name"].str[:-2].str.strip("_") # name from path column because original name can be inconsistent cos tesseract
    u_df["name_fp"] = u_df["name"].str[:-2].str.strip("_") # name from path column because original name can be inconsistent cos tesseract
    r_df = df.groupby("name_fp").nth(0)[["area_total", "building name"]] #results dataframe indexed by name from path
    print(r_df)
    print(u_df)
    print(df)

    cp = 1006           #could calculate for marginally increased accuracy
    air_density = 1.22          #similarly^

    r_df = conduction(df, u_df, r_df)
    r_df, envelope = ventilation(df, r_df, cp, air_density, u_df)
    print("envelope", envelope)
    r_df = capacity(df, u_df, r_df, cp, air_density, envelope)
    r_df.to_csv(cur_dir+"\\results\\Thermal Results.csv")
    print(r_df)

main()






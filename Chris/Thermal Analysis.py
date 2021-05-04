
#%%
import pandas as pd

def conduction(df, u_df, r_df):
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

def ventilation(df, u_df, r_df):
    cp = 1.006#could calculate for marginally increased accuracy
    hour = 60*60 # just hour in sec
    roof_area = df.groupby("name_fp")["surface_area_roof"].sum() #adding areas to find total surface area - envelope
    wall_area = df.groupby("name_fp")["surface_area_wall"].sum()
    floor_area = df.groupby("name_fp")["area_total"].nth(0)
    envelope = roof_area + wall_area + floor_area
    print(envelope)

    r_df["ventilation_constant"] = u_df.groupby("name_fp")["permeability"].nth(0).mul(envelope)*cp/hour
    print(r_df)


U_value_csv_path = r"C:\Users\rawdo\Documents\year 4\project\U values.csv"
volume_csv_path = r"C:\Users\rawdo\Documents\year 4\project\Building Plans\campus\PNGs\floor_volumes_1.0.csv"
df = pd.read_csv(volume_csv_path, index_col = "index")
u_df = pd.read_csv(U_value_csv_path)
df = df.drop(columns = ["Unnamed: 0", "scale", "paper size", "area_air", "perimeter", "area_wall"])
df["name_fp"] = df["name"].str[:-2].str.strip("_") # name from path column because original name can be inconsistent cos tesseract
u_df["name_fp"] = u_df["name"].str[:-2].str.strip("_") # name from path column because original name can be inconsistent cos tesseract
r_df = df.groupby("name_fp").nth(0)[["area_total", "building name"]] #results dataframe indexed by name from path
print(r_df)
print(u_df)
print(df)
r_df = conduction(df,u_df, r_df)
print(r_df)
ventilation(df, u_df, r_df)
#%%
def thermalise(df, u_df):
    
    return





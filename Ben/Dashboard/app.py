import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
from datetime import date
from DataGraph import time_graph

#Data
    #Turbine
turbine_filepath = 'G:/4th Year Project/Dashboard/turbine_data.csv'
turbinedata = pd.read_csv(turbine_filepath)

    #Thermal Efficiency
GF_eff_filepath = 'G:/4th Year Project/Dashboard/Individual Data/GF_eff.csv'
GF_eff = pd.read_csv(GF_eff_filepath)

    #Historical Data
BT_occ_h_filepath = 'G:/4th Year Project/Dashboard/Individual Data/BT occ history.csv'
BT_occ_h = pd.read_csv(BT_occ_h_filepath)

BT_therm_h_filepath = 'G:/4th Year Project/Dashboard/Individual Data/BT_hitorical_thermal_kW.csv'
BT_therm_h = pd.read_csv(BT_therm_h_filepath)

GF_occ_h_filepath = 'G:/4th Year Project/Dashboard/Individual Data/GF_occ_history.csv'
GF_occ_h = pd.read_csv(GF_occ_h_filepath)

GF_therm_h_filepath = 'G:/4th Year Project/Dashboard/Individual Data/GF_thermal_history.csv'
GF_therm_h = pd.read_csv(GF_therm_h_filepath)

    #Forecasts
GF_elec_pred_filepath = 'G:/4th Year Project/Dashboard/Individual Data/george_fox_preds.csv'
GF_elec_pred = pd.read_csv(GF_elec_pred_filepath)

#Graphs
    #Turbine
turbine_energy_generated = time_graph(turbinedata.Timestamp, turbinedata['Average Output Power (kW)'], 'royalblue')
turbine_energy_generated.update_layout(xaxis_title="Timestamp",
                                       yaxis_title="Energy Generation kWH")
turbine_average_wind_speed = time_graph(turbinedata.Timestamp, turbinedata['Average Wind Speed (m/s)'], 'limegreen')
turbine_average_wind_speed.update_layout(xaxis_title="Timestamp",
                                         yaxis_title="Average Wind Speed m/s")
turbine_saving = time_graph(turbinedata.Timestamp, turbinedata['Saving (£)'], 'firebrick')
turbine_saving.update_layout(xaxis_title="Timestamp",
                             yaxis_title="Savings (£)")


    #Thermal Efficiency
Therm_eff = go.Figure()
# Create and style traces
Therm_eff.add_trace(go.Scatter(x=GF_eff.time, y=GF_eff['Air Temperature'], name='Air Temperature',
                             line=dict(color='firebrick', width=4)))
Therm_eff.add_trace(go.Scatter(x=GF_eff.time, y=GF_eff['Wall Temperature'], name = 'Wall Temperature',
                             line=dict(color='royalblue', width=4)))
Therm_eff.add_trace(go.Scatter(x=GF_eff.time, y=GF_eff['Data'], name='Data',
                             line=dict(color='limegreen', width=4,)))
Therm_eff.update_layout(title='Cooling Curves',
                       xaxis_title='Timestamp (Hours After Heating Shutdown)',
                       yaxis_title='Temperature (DegC)')

    #Forecasts
elec = px.line(GF_elec_pred, x='Timestamp', y='Forecasted Reading (kWh)')

    #Historical
BT_occ_hist = time_graph(BT_occ_h.Timestamp, BT_occ_h.Numbers, 'royalblue')
BT_occ_hist.update_layout(title='Bowland Tower Occupancy History',
                          xaxis_title="Timestamp",
                          yaxis_title="Number of People",)
BT_therm_hist = time_graph(BT_therm_h.Timestamp, BT_therm_h.Thermal_Rate, 'limegreen')
BT_therm_hist.update_layout(title='Bowland Tower Thermal Power',
                            xaxis_title="Timestamp",
                            yaxis_title="Energy Usage (kWh)",)
GF_occ_hist = time_graph(GF_occ_h.Timestamp, GF_occ_h.Numbers, 'royalblue')
GF_occ_hist.update_layout(title='George Fox Occupancy History',
                            xaxis_title="Timestamp",
                            yaxis_title="Number of People",)
GF_therm_hist = time_graph(GF_therm_h.Timestamp, GF_therm_h['Thermal Power'], 'limegreen')
GF_therm_hist.update_layout(title='George Fox Thermal Power',
                            xaxis_title="Timestamp",
                            yaxis_title="Energy Usage (kWh)",)

#Setup
external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']
app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

#Layout of page
app.layout = html.Div(
    [
    
    #Title and Selection
    html.Div(
        [
            html.H1(children='Energy Management Dashboard',
                    style={'textAlign':'center'}),
            html.Div(
                [
                    html.Label('Select Building',
                               style={'textAlign':'center'}),
                    dcc.Dropdown(id='dropdownMain',
                                 options=[
                                     {'label': 'Wind Turbine', 'value': 'WT'},
                                     {'label': 'George Fox', 'value': 'GF'},
                                     {'label': 'Bowland Tower', 'value': 'BT'}],
                                 value='')
                    ],
                style={'margin':'10px 800px 50px 800px'}
                )
            ]
        ),

    #Buildings
    html.Div(
        [
            #Building Overview
            html.Div(
                [
                    #Heading
                    html.H3('Building Overview',
                            style={'textAlign':'center', 'text-decoration':'underline'}
                            ),
                    #Floor Plan and Map
                    html.Div(
                        [
                            #Floor Plan
                            html.Iframe(src=app.get_asset_url('Bowland Tower Floor Plan.png'),
                                     id='Floor Plan',
                                     style={'width':'800px','height':'500px', 'objectFit':'contain'}
                                     ),
                            #Map
                            html.Img(src=app.get_asset_url('Bowland Tower Map.png'),
                                     id='Map',
                                     style={'width':'800px', 'height':'500px', 'objectFit':'cover'}
                                     )],
                        id='Floor Plan and Map',
                        style={'columnCount':2, 'textAlign':'center', 'margin':'50px 20px 20px 20px'}
                        ),

                    #Data Quality
                    html.Div(
                        [
                            html.Div(
                                [
                                    html.Img(src=app.get_asset_url('BT Data Quality.png'),
                                             id='Data Quality',
                                             )
                                    ],
                                ),
                            html.Div(
                                [
                                    html.H3('Data Quality Metric'),
                                    html.H1('82B', id='DQMnum',
                                            style={'fontSize':'100px', 'color':'Blue'})
                                    ],
                                style={'textAlign':'center', 'padding':'325px'}
                                )
                            ],
                        
                        id='Data Quality Container',
                        style={'columnCount':2, 'textAlign':'center'},
                        ),
                    ],
                
                id='Building Overview',
                style={}
                ),

            #Thermal Efficiency
            html.Div(
                [
                    #Heading
                    html.H3('Thermal Efficiency',
                            style={'textAlign':'center','text-decoration':'underline'}
                            ),
                    html.Div(
                        [
                            dcc.Graph(figure=Therm_eff, style={'width':'1000px',
                                                               'height':'500px',
                                                               'margin':'10px 490px 10px 490px'})
                            ],
                        style={'textAlign':'center'}
                        )
                    ],

                id='Thermal Efficiency',
                style={}
                ),

            #Forecasts
            html.Div(
                [
                    #Heading 
                    html.H3('Forecast',
                            style={'textAlign':'center',
                                   'text-decoration':'underline'}
                            ),
                    dcc.Graph(figure=elec, id='Electric Forecast')
                    ],
                
                id='Forecasts',
                style={}
                ),

            #Historical Data
            html.Div(
                [
                    #Heading
                    html.H3('Historical Data',
                            style={'textAlign':'center',
                                   'text-decoration':'underline'}
                            ),
                    html.Div(
                        [
                            dcc.Graph(figure=BT_occ_hist,
                                      id='occ Hist'
                                      ),
                            dcc.Graph(figure=BT_therm_hist,
                                      id='therm Hist'
                                      )
                            ]
                        )
                        
                    ],
                
                id='Historical Data',
                style={}
                )
            ],
        
        id='Buildings',
        style={'display': 'block'}
        
        ),
                    

    
    #Wind Turbine
     html.Div(
        [
            html.Div(
                [
                    #Heading 1
                    html.H3('Energy Generated',
                            style={'textAlign':'center', 'text-decoration':'underline'}
                            ),
                    #Graph Energy Generated
                    html.Div(
                        [
                            dcc.Graph(figure=turbine_energy_generated,
                                      id='Turbine_energy_generated'
                                      )
                
                            ],
                        ),
                    #Heading 2
                    html.H3('Average Wind Speed',
                            style={'textAlign':'center', 'text-decoration':'underline'}
                            ),
                    #Graph Energy Generated
                    html.Div(
                        [
                            dcc.Graph(figure=turbine_average_wind_speed,
                                      id='Turbine average wind speed'
                                      )
                            ]
                        ),
                    #Heading 3
                    html.H3('Savings',
                            style={'textAlign':'center', 'text-decoration':'underline'}
                            ),
                    #Graph Saving
                    html.Div(
                        [
                            dcc.Graph(figure=turbine_saving,
                                      id='Turbine saving'
                                      )
                            ]
                        ),
                    ]
                )
            ],
        
        id='Wind Turbine',
        style={'display': 'block'}

        )

#Bottom
])


#Callbacks
@app.callback(
    Output('Buildings', 'style'),
    Output('Wind Turbine', 'style'),
    Input('dropdownMain', 'value'))
def show_state(state):
    if state == '':
        return {'display':'none'}, {'display':'none'}
    if state == 'WT':
        return {'display':'none'}, {'display':'block'}
    else:
        return {'display':'block'}, {'display':'none'}

@app.callback(
    Output('Data Quality', 'src'),
    Output('Map', 'src'),
    Output('Floor Plan', 'src'),
    Output('occ Hist', 'figure'),
    Output('therm Hist', 'figure'),
    Output('DQMnum','children'),
    Input('dropdownMain', 'value'))
def update_data(building):
    if building == 'BT':
        dq = app.get_asset_url('BT Data Quality.png')
        m = app.get_asset_url('Bowland Tower Map.png')
        fp = app.get_asset_url('Bowland Tower Floor Plan.png')
        oh = BT_occ_hist
        th = BT_therm_hist
        dqm = '75C'
        return dq, m, fp, oh, th, dqm
    
    else:
        dq = app.get_asset_url('GF Data Quality.png')
        m = app.get_asset_url('George Fox Map.png')
        fp = app.get_asset_url('George Fox Floor Plan.png')
        dqm = '80A'
        return dq, m, fp, GF_occ_hist, GF_therm_hist, dqm

if __name__ == '__main__':
    app.run_server(debug=True)
    

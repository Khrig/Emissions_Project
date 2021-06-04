import dash
import dash_core_components as dcc
import plotly.graph_objects as go
import pandas as pd
from datetime import date

def time_graph(x, y, colour):

    name = go.Figure()
    name.add_trace(go.Scatter(x=list(x), y=list(y), line=dict(color=colour)))
    
    # Add range slider
    name.update_layout(
        xaxis=dict(
            rangeselector=dict(
                buttons=list([
                    dict(count=1,
                         label="1h",
                         step="hour",
                         stepmode="backward"),
                    dict(count=1,
                         label="1d",
                         step="day",
                         stepmode="backward"),
                    dict(count=7,
                         label="1w",
                         step="day",
                         stepmode="backward"),
                    dict(step="all")
                ])
            ),
            rangeslider=dict(
                visible=True
            ),
            type="date"
        )
    )
    
    return name

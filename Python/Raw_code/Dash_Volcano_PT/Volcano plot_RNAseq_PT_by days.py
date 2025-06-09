"""
Interactive Volcano Plot Dashboard – Gene Expression Changes after PP Treatment

🔗 Interactive version available at: https://your-dashboard-link.here

This Dash application allows users to interactively explore differential gene expression 
in primary tumors of PP-treated mice across three experimental time points (7, 9, and 12 days). 
The data is visualized using volcano plots, which highlight significantly upregulated or downregulated genes in mice primary tumours.

Input:
- A tab-separated text file:
  summary_table_supervised_PT_PP_PT_CTRL_and_PT_PP_PT_CTRL_long_7_9_12_230524.txt
- Required columns:
    - 'GeneName': gene identifier
    - 'folds_median_PT_PP_PT_CTRL_long_{day}': median fold change (FC) for each day
    - 'ttest_unpaired_p_PT_PP_PT_CTRL_long_{day}': unpaired t-test p-value for each day

Output:
- Interactive volcano plot with:
    - X-axis: log₂(Fold Change)
    - Y-axis: –log₁₀(p-value)
    - Point color: 
        - 'Increased' (log2FC ≥ 1 and p < 0.05)
        - 'Decreased' (log2FC ≤ -1 and p < 0.05)
        - 'Neutral' otherwise
    - Hover tooltip with gene name
    - Threshold lines at log₂FC = ±1 and –log₁₀(p) = 1.3

Features:
- Day selection via dropdown menu (7, 9, 12 days post-treatment)
- Dynamic updates of volcano plot on selection
- Publication-ready styling and layout

Dependencies:
- dash
- pandas
- numpy
- plotly
- os

To run locally:
1. Install dependencies: `pip install dash pandas numpy plotly`
2. Place the input `.txt` file in the same directory
3. Run the script: `python app.py`
"""

import pandas as pd
import numpy as np
import plotly.express as px
from dash import Dash, dcc, html, Input, Output
import os

# Load the input dataset
df = pd.read_csv('summary_table_supervised_PT_PP_PT_CTRL_and_PT_PP_PT_CTRL_long_7_9_12_230524.txt', sep='\t')
df.drop(columns=['Chr', 'Start', 'End', 'GeneLength'], inplace=True)

# Compute log2(Fold Change) and -log10(p-value) for each time point
for day in [7, 9, 12]:
    df[f'-log10(p){day}'] = -np.log10(df[f'ttest_unpaired_p_PT_PP_PT_CTRL_long_{day}'])
    df[f'log2(FC){day}'] = np.log2(df[f'folds_median_PT_PP_PT_CTRL_long_{day}'])

# Define a function to classify gene regulation status
def assign_regulation(logfc, logp):
    if logp > 1.3:
        if logfc >= 1:
            return 'Increased'
        elif logfc <= -1:
            return 'Decreased'
    return 'Neutral'

# Create the Dash application
app = Dash(__name__)
app.layout = html.Div([
    html.H2("Volcano plot – Days of PP Treatment", style={'textAlign': 'center'}),
    dcc.Dropdown(
        id='day-selector',
        options=[{'label': f'{day} days', 'value': day} for day in [7, 9, 12]],
        value=9,
        clearable=False
    ),
    dcc.Graph(id='volcano-plot')
])

# Define callback to update volcano plot based on selected time point
@app.callback(
    Output('volcano-plot', 'figure'),
    Input('day-selector', 'value')
)
def update_volcano_plot(day):
    temp_df = df.copy()
    temp_df['log2FC'] = temp_df[f'log2(FC){day}']
    temp_df['-log10p'] = temp_df[f'-log10(p){day}']
    temp_df['Regulation'] = temp_df.apply(lambda row: assign_regulation(row['log2FC'], row['-log10p']), axis=1)

    fig = px.scatter(
        temp_df,
        x='log2FC',
        y='-log10p',
        color='Regulation',
        color_discrete_map={
            'Increased': '#AF4647',
            'Decreased': '#517FBC',
            'Neutral': 'lightgray'
        },
        hover_name='GeneName',
        title=f'Volcano Plot – {day} Days of PP Treatment',
        height=700,
        width=800
    )

    # Add threshold lines for significance
    fig.add_hline(y=1.3, line_dash='dash', line_color='gray')
    fig.add_vline(x=1, line_dash='dash', line_color='gray')
    fig.add_vline(x=-1, line_dash='dash', line_color='gray')

    fig.update_layout(
        xaxis_title='log₂(Fold Change)',
        yaxis_title='-log(p)',
        font=dict(size=14),
        legend=dict(title='Regulation'),
        plot_bgcolor='white'
    )

    return fig
    
# Run the app
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8051))
    app.run(debug=True, host='0.0.0.0', port=port)

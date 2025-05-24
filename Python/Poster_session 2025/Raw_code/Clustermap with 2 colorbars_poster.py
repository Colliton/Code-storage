"""
Z-scored Immune Cell Abundance in Mice – Poster Visualization
-------------------------------------------------------------

This script generates a poster-ready clustermap showing Z-scored immune cell abundances 
in mouse tumor samples. The data is derived from ImmuCellAI-mouse analysis. The heatmap 
is sorted by experimental group and includes custom color annotations for group identity 
(Control vs Treated) and infiltration score.

Features:
- Heatmap rows: immune cell types
- Heatmap columns: individual mice
- Cell color scale: Z-scores (normalized abundances)
- Column annotations:
  - Group: Control (blue), Treated (red)
  - Infiltration Score: custom blue gradient scale (left-side colorbar)
- Z-score colorbar: shown on the right
- Optimized for poster presentation (Calibri font, large labels, high resolution)

Input:
- Excel file with immune cell proportions per mouse: 
  'ImmuCellAI_mouse_abundance_result_threshold_9.xlsx'

Dependencies:
- pandas
- seaborn
- matplotlib
- scipy
- openpyxl

How to run:
- Make sure the Excel file is in the working directory
- Run the script to generate and save the heatmap

Output:
- PNG file: 'Z-scored Immune Cell Abundance in Mice_poster.png'

Data source:
- Immune cell abundances estimated via: http://bioinfo.life.hust.edu.cn/web/ImmuCellAI-mouse/

"""

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.colors import Normalize
from matplotlib.cm import ScalarMappable
from scipy.stats import zscore
from matplotlib.colors import LinearSegmentedColormap

# Set font for the entire figure
plt.rcParams['font.family'] = 'Calibri'

# Load and clean the dataset
file_path = "ImmuCellAI_mouse_abundance_result_threshold_9.xlsx"
df = pd.read_excel(file_path)
df = df[df["Mouse number"] != 311]  # Remove mouse 311

# Set mouse number as index and sort by group
df.set_index("Mouse number", inplace=True)
df_sorted = df.sort_values("Group")

# Select immune cell columns and compute Z-scores
cell_types = df.columns.difference(['Group', 'Infiltration_score'])
zscored = df_sorted[cell_types].apply(zscore)
zscored.columns = zscored.columns.str.replace('_', ' ')

# Custom color map for Infiltration Score
colors = [
    "#DCE1EA",  # very light version of #AAB8CD
    "#B7C4D9",  # lighter #8B9BB2
    "#899BB5",  # lighter #53637D
    "#5A6A85"    # lighter #2E3545
]
custom_cmap = LinearSegmentedColormap.from_list("custom_cmap", colors)

# Assign colors to groups
group_palette = {'Control': '#517FBC', 'Treated': '#AF4647'}
group_colors = df_sorted['Group'].map(group_palette)

# Assign colors to infiltration scores
norm = Normalize(vmin=df_sorted['Infiltration_score'].min(), vmax=df_sorted['Infiltration_score'].max())
cmap = custom_cmap
infiltration_colors = df_sorted['Infiltration_score'].map(lambda x: cmap(norm(x)))

# Create column color bar (group and infiltration score)
col_colors = pd.DataFrame({
    'Group': group_colors,
    'Infiltration Score': infiltration_colors
}, index=df_sorted.index)

# Generate the clustermap
g = sns.clustermap(
    zscored.T,
    cmap="vlag",
    center=0,
    col_colors=col_colors,
    col_cluster=False,
    row_cluster=False,
    xticklabels=True,
    yticklabels=True,
    figsize=(20, 16),
    cbar_pos=None
)

# Customize column color bar font
tick_labels = g.ax_col_colors.yaxis.get_ticklabels()
for tick in tick_labels:
    tick.set_fontsize(14)
    tick.set_fontweight('bold')

# Add Z-score colorbar on the right
norm_zscore = Normalize(vmin=zscored.min().min(), vmax=zscored.max().max())
sm = ScalarMappable(cmap="vlag", norm=norm_zscore)
cbar_ax = g.fig.add_axes([1.0, 0.2, 0.015, 0.4])
cbar = g.fig.colorbar(sm, cax=cbar_ax)
cbar.set_label("Z-score", fontsize=14, rotation=-90, labelpad=10)
cbar.ax.tick_params(labelsize=12)

# Add title
g.fig.suptitle("Z-scored Immune Cell Abundance in Mice\nSorted by Experimental Group", fontsize=16, x=0.6, y=0.8)

# Add group legend under the heatmap
legend_patches = [Patch(facecolor=color, label=label) for label, color in group_palette.items()]
g.ax_heatmap.legend(
    handles=legend_patches,
    title="Group",
    title_fontsize=14,
    fontsize=12,
    loc='upper center',
    bbox_to_anchor=(0.5, -0.08),
    ncol=2,
    frameon=False
)

# Add Infiltration Score colorbar on the left
cbar_ax_infiltration = g.fig.add_axes([0.25, 0.25, 0.015, 0.4])
cbar_infiltration = g.fig.colorbar(ScalarMappable(norm=norm, cmap=cmap), cax=cbar_ax_infiltration)
cbar_infiltration.set_label('Infiltration Score', fontsize=14, labelpad=-60, rotation=90)
cbar_infiltration.ax.tick_params(labelsize=12)

# Adjust plot layout
g.fig.subplots_adjust(left=0.15, right=0.9, top=0.9, bottom=0.15)

# Customize axis labels and ticks
g.ax_heatmap.set_xlabel("Mouse number", fontsize=14)
g.ax_heatmap.set_xticklabels(g.ax_heatmap.get_xticklabels(), fontsize=14, rotation=45)
g.ax_heatmap.set_yticklabels(g.ax_heatmap.get_yticklabels(), fontsize=14)

# Save the figure
plt.savefig('Z-scored Immune Cell Abundance in Mice_poster.png', bbox_inches='tight', pad_inches=0.1)
plt.show()

"""
Clustermap of Z-score Normalized Lipid Abundance in Primary Tumours (Excluding Healthy Mouse 311)

This script generates a clustermap showing standardized lipid class abundances 
in primary tumours of mice treated with Pyrvinium Pamoate (PP) or DMSO (CTRL).
Mouse 311, which did not develop a tumor (healthy), is excluded from the analysis.
Data is z-score normalized per lipid class to allow comparison across samples.

Input:
- Excel file ('Lipids mol%.xlsx') with:
    - Rows: Lipid classes
    - Columns: Group_MouseID (e.g., CTRL_101, PP_203)
    - Values: Relative abundance in %mol

Output:
- Z-score normalized clustermap of lipid classes
- Manual colorbar to indicate normalized intensity
- Annotated heatmap with mouse IDs and group labels

Dependencies:
- pandas
- seaborn
- matplotlib
- scipy
"""

import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
from scipy.stats import zscore
import matplotlib.colors as mcolors

# Set font globally
plt.rcParams['font.family'] = 'Calibri'

# Load data from Excel
lipids = pd.read_excel('Lipids mol%.xlsx')

# Set lipid class as index
df = lipids.set_index("Lipid class")

# Split columns into MultiIndex: (Group, Mouse)
df.columns = pd.MultiIndex.from_tuples(
    [(col.split("_")[0], col.split("_")[1]) for col in df.columns],
    names=["Group", "Mouse"]
)

# Exclude mouse 311
df = df.loc[:, df.columns.get_level_values("Mouse") != "311"]

# Normalize data (z-score by row/lipid class)
df_z = df.apply(zscore, axis=1)

# Separate CTRL and PP groups
group_labels = df.columns.get_level_values("Group")
mouse_labels = df.columns.get_level_values("Mouse")
df_ctrl = df_z.loc[:, group_labels == "CTRL"]
df_pp = df_z.loc[:, group_labels == "PP"]

# Concatenate for visualization
df_clustered = pd.concat([df_ctrl, df_pp], axis=1)

# Create clustermap (row-clustered only, no default colorbar)
g = sns.clustermap(
    df_clustered,
    cmap='coolwarm',
    linewidths=0.5,
    linecolor="white",
    figsize=(12, 10),
    cbar=False,
    row_cluster=True,
    col_cluster=False,
    annot=True,
    fmt=".2f",
    dendrogram_ratio=(0.05, 0.01),
)

# Remove unused axes (e.g., col dendrogram, colorbar space)
for ax in g.fig.axes:
    if ax not in [g.ax_heatmap, g.ax_row_dendrogram]:
        g.fig.delaxes(ax)

# Manual colorbar setup
norm = mcolors.Normalize(vmin=df_clustered.min().min(), vmax=df_clustered.max().max())
sm = plt.cm.ScalarMappable(cmap='coolwarm', norm=norm)
sm.set_array([])

# Add colorbar to the right of the plot
cbar_ax = g.fig.add_axes([0.967, 0.4, 0.015, 0.4])
cbar = g.fig.colorbar(sm, cax=cbar_ax)
cbar.set_label("Intensity (%mol) z-score normalized", fontsize=12, rotation=270, labelpad=10)
cbar.ax.yaxis.set_label_position('right')

# Add vertical line to separate groups
g.ax_heatmap.axvline(x=df_ctrl.shape[1], color='white', linewidth=3)

# Set mouse number labels (x-axis)
g.ax_heatmap.set_xticks(range(len(mouse_labels)))
g.ax_heatmap.set_xticklabels(mouse_labels, rotation=45, fontsize=12)

# Set lipid class labels (y-axis)
g.ax_heatmap.set_yticklabels(g.ax_heatmap.get_yticklabels(), fontsize=12)

# Add group labels below plot
ctrl_center = (df_ctrl.shape[1] - 1) / 2
pp_center = df_ctrl.shape[1] + (df_pp.shape[1] - 1) / 2
g.ax_heatmap.text(ctrl_center, -0.7, "CTRL", ha='center', va='top', fontsize=12, transform=g.ax_heatmap.transData)
g.ax_heatmap.text(pp_center, -0.7, "PP", ha='center', va='top', fontsize=12, transform=g.ax_heatmap.transData)

# Add plot title and axis labels
g.ax_heatmap.set_title("Z-score normalized lipid classes in CTRL and PP treated primary tumours", fontsize=16, fontweight='bold', pad=35)
g.ax_heatmap.set_xlabel("Mouse number", fontsize=14)
g.ax_heatmap.set_ylabel("Lipid class", rotation=270, labelpad=-0.5, fontsize=14)

# Adjust margins to fit everything
g.fig.subplots_adjust(bottom=0.2, right=0.88)

# Uncomment to save the figure
# plt.savefig("Clustermap_lipids_PT_no311.png", dpi=300, bbox_inches="tight")

plt.show()

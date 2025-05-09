""" 
Volcano Plot for Differential Gene Expression in 4T1 Cells Treated with Pyrvinium Pamoate

Volcano plot from RNA-seq results comparing control 4T1 cell lines
and those treated with Pyrvinium Pamoate (PP). Genes are classified as increased, decreased, or neutral
based on log2 fold change and p-value thresholds. Genes with |log2FC| ≤ 1 and -log10(p) ≤ 1.3 are excluded from further analysis.

Input:
- Excel file (4T1_volcano.xlsx) with columns:
    - 'log2(fold change)': log2 fold change values
    - '-log(p)': negative log10 p-values
    - 'Regulation': categorical gene regulation status (Increased/Decreased/Neutral)

Output:
- Volcano plot showing differentially expressed genes
- Threshold lines at log2FC = ±1 and -log10(p) = 1.3
- Plot saved as 'volcano.png'

Dependencies:
- pandas
- seaborn
- matplotlib
- numpy
"""

# Import required libraries
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np

# Set the figure size
plt.figure(figsize = (12,6))

# Load RNA-seq results from an Excel file
genes = pd.read_excel('4T1_volcano.xlsx')
genes

# Create a volcano plot using seaborn's scatterplot
ax = sns.scatterplot(data = genes, x = 'log2(fold change)', y = '-log(p)',
                    hue = 'Regulation', hue_order = ['Increased', 'Decreased', 'Neutral'],
                    palette = ['red', 'blue', 'lightgray'], sizes = (40, 400))


# Add threshold lines for significance
ax.axhline(1.3, zorder = 0, c = 'k', lw = 1, ls = '--')
ax.axvline(1, zorder = 0, c = 'k', lw = 1, ls = '--')
ax.axvline(-1, zorder = 0, c = 'k', lw = 1, ls = '--')


# Customize the legend
plt.legend(loc = 1, bbox_to_anchor = (1.3,1), frameon = False, prop = {'family': 'Times New Roman','weight':'light'})


# Enhance plot aesthetics: visible borders
for axis in ['bottom', 'left']:
    ax.spines[axis].set_linewidth(1)

# Hide top and right borders
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

# Customize tick appearance
ax.tick_params(width = 2)
plt.xticks(size = 10, weight = 'light')
plt.yticks(size = 10, weight = 'light')

# Add axis labels using LaTeX formatting
plt.xlabel("$log_{2}$ fold change", size = 12, fontfamily='Times New Roman')
plt.ylabel("-$log_{10}$ p", size = 12, fontfamily='Times New Roman')

# Add title
ax.set_title('RNA-seq PP 5.0 vs CTRL', fontsize=14, fontweight='bold', pad = 20, fontfamily='Times New Roman')

# Save the plot as a high-resolution PNG file
#plt.savefig('volcano.png', dpi = 300, bbox_inches = 'tight', facecolor = 'white')
plt.show()

'''
Lipid Class Analysis Script

This script processes an Excel file containing lipid class composition (%mol) in tumor samples
from mice divided into experimental groups (CTRL and PP). For each lipid class (sheet), it:

1. Excludes data from mouse #311,
2. Tests each lipid species for statistical differences between groups,
3. Selects lipids with significant differences (p < 0.05),
4. Plots boxplots + jitter plots for significant lipids,
5. Saves plots to PNG files,
6. Aggregates all statistical results into a single Excel file.

Input:
- Excel file "Lipid_classes_%mol.xlsx" with multiple sheets, each containing lipid data.
- Each sheet must include columns: 'Mouse number', 'Group', and lipid species.

Output:
- PNG plots for each lipid class with significant differences, saved in folder "lipid_plots".
- Excel file "Results_summary.xlsx" aggregating statistical test results across sheets.

Dependencies:
- pandas
- scipy.stats
- seaborn
- matplotlib.pyplot
- os
'''

import pandas as pd
import scipy.stats as stats
import seaborn as sns
import matplotlib.pyplot as plt
import os

# Path to Excel file
file_path = "Lipid_classes_%mol.xlsx"
excel_file = pd.ExcelFile(file_path)
sheet_names = excel_file.sheet_names

# Folder for plots
output_folder = "lipid_plots"
os.makedirs(output_folder, exist_ok=True)

# Storage for aggregated results
all_results = []

# Exclude specific mouse
exclude_mouse = 311

# Analyze each sheet (lipid class)
for sheet in sheet_names:
    df = pd.read_excel(file_path, sheet_name=sheet)
    if 'Mouse number' not in df.columns or 'Group' not in df.columns:
        continue  # Skip incomplete or empty sheets

    # Remove excluded mouse
    df = df[df['Mouse number'] != exclude_mouse]

    # Melt to long format
    df_melted = df.melt(id_vars=['Mouse number', 'Group'], var_name='Lipid', value_name='Value')

    significant_lipids = []
    p_values = {}
    results = []

    for lipid in df.columns[2:]:  # Skip 'Mouse number' and 'Group'
        group_ctrl = df_melted[(df_melted['Lipid'] == lipid) & (df_melted['Group'] == 'CTRL')]['Value']
        group_pp = df_melted[(df_melted['Lipid'] == lipid) & (df_melted['Group'] == 'PP')]['Value']

        # Choose statistical test based on normality
        if group_ctrl.nunique() == 1 or group_pp.nunique() == 1:
            stat, p_value = stats.mannwhitneyu(group_ctrl, group_pp, alternative='two-sided')
            test_used = 'Mann-Whitney U'
        else:
            _, p_norm_ctrl = stats.shapiro(group_ctrl)
            _, p_norm_pp = stats.shapiro(group_pp)

            if p_norm_ctrl > 0.05 and p_norm_pp > 0.05:
                stat, p_value = stats.ttest_ind(group_ctrl, group_pp, equal_var=False)
                test_used = 't-test'
            else:
                stat, p_value = stats.mannwhitneyu(group_ctrl, group_pp, alternative='two-sided')
                test_used = 'Mann-Whitney U'

        results.append({
            'Sheet': sheet,
            'Lipid': lipid,
            'Statistic': stat,
            'p-value': p_value,
            'Test': test_used
        })

        if p_value < 0.05:
            significant_lipids.append(lipid)
            p_values[lipid] = p_value

    results_df = pd.DataFrame(results)
    all_results.append(results_df)

    # Plot only significant lipids
    if significant_lipids:
        df_significant = df_melted[df_melted['Lipid'].isin(significant_lipids)]

        plt.figure(figsize=(10, 6))

        # Define colors
        transparent_pink = (1.0, 0.5, 0.5, 1)
        transparent_purple = (0.6, 0.2, 0.7, 1)

        palette = {'CTRL': 'lightgray', 'PP': 'darkgray'}
        palette2 = {'CTRL': transparent_purple, 'PP': transparent_pink}

        # Boxplot
        ax = sns.boxplot(data=df_significant, x='Lipid', y='Value', hue='Group', palette=palette2, showfliers=False)

        # Stripplot overlay
        sns.stripplot(data=df_significant, x='Lipid', y='Value', hue='Group', palette=palette,
                      dodge=True, jitter=True, marker='o', alpha=0.7, linewidth=0.5, size=7)

        # Annotate p-values
        for i, lipid in enumerate(significant_lipids):
            p = p_values[lipid]
            x_pos = i
            y_max = df_significant[df_significant['Lipid'] == lipid]['Value'].max()
            y_offset = y_max * 0.05
            ax.text(x_pos, y_max + y_offset, f"p={p:.3f}", ha='center', fontsize=10, color='black')

        sns.despine(top=True, right=True)

        plt.xticks(rotation=45)
        plt.title(f"{sheet} [%mol] (p < 0.05)")
        plt.legend(title="Group", loc='upper left', bbox_to_anchor=(1, 1))
        plt.tight_layout()
        plt.savefig(os.path.join(output_folder, f"{sheet}.png"), dpi=300)
        plt.close()

# Save combined results to Excel
final_results_df = pd.concat(all_results, ignore_index=True)
final_results_df.to_excel("Results_summary.xlsx", index=False)

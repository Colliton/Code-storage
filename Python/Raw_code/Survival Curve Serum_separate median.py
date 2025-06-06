"""
Survival Analysis of Mice Based on PUFA Serum Levels

Kaplan-Meier survival analysis separately for two groups of mice Treated and Control (PP and CTRL) 
based on the median concentrations of individual polyunsaturated fatty acids (PUFAs).
For each lipid, mice are split into "above median" and "below median" subgroups.
Survival curves are plotted and log-rank tests are conducted to compare survival distributions.

Input:
- Excel file (PUFA_serum_%mol.xlsx) containing:
    - Group assignment (PP/CTRL)
    - Number of days since PP administration
    - Lipid concentration values [%mol]

Output:
- Kaplan-Meier survival plots for each lipid (PP and CTRL groups)
- Log-rank p-values annotated on the plots

Dependencies:
- pandas
- matplotlib
- lifelines
- scipy
"""

# Import required libraries
import pandas as pd
import matplotlib.pyplot as plt
from lifelines import KaplanMeierFitter
from lifelines.statistics import logrank_test
from scipy.stats import shapiro, mannwhitneyu, ttest_ind

# Load Excel data containing survival times and lipid concentrations
file_path = 'PUFA_serum_%mol.xlsx'
df = pd.read_excel(file_path)

# Split data into PP and CTRL groups based on the 'Group' column
pp_group = df[df['Group'] == 'PP']
ctrl_group = df[df['Group'] == 'CTRL']

# Assume all mice died (i.e., event occurred for all)
df['Event'] = 1

# Prepare list for potential statistical results (not used later in this version)
stat_results = []

# Select lipid columns (assuming they start at the 5th column)
lipids = df.columns[4:]

# Plot Kaplan-Meier curves for the PP group
def plot_km_for_pp(lipid):
    # Median split based on lipid concentration
    median_pp = pp_group[lipid].median()
    above_median_pp = pp_group[pp_group[lipid] > median_pp]
    below_median_pp = pp_group[pp_group[lipid] <= median_pp]
    
    # Perform log-rank test between above/below median groups
    results = logrank_test(above_median_pp['Number of days since PP administration'],
                           below_median_pp['Number of days since PP administration'],
                           event_observed_A=above_median_pp['Event'],
                           event_observed_B=below_median_pp['Event'])
    p_value_log = results.p_value
    
    # Plot survival curves
    kmf = KaplanMeierFitter()
    plt.figure(figsize=(8, 6))
    
    kmf.fit(above_median_pp['Number of days since PP administration'], event_observed=above_median_pp['Event'])
    kmf.plot(label='Above Median (PP)')
    
    kmf.fit(below_median_pp['Number of days since PP administration'], event_observed=below_median_pp['Event'])
    kmf.plot(label='Below Median (PP)')
    
    # Annotate with p-value
    plt.text(0.05, 0.05, f'Log-rank p-value: {p_value_log:.3f}', transform=plt.gca().transAxes,
             fontsize=9, bbox=dict(facecolor='white', alpha=0.7, edgecolor='black'))

    # Sanitize lipid name for file naming
    safe_lipid_name = lipid.replace("(", "").replace(")", "").replace("/", "_").replace("\\", "_")

    # Finalize and save plot
    plt.title(f"Survival Curve for {lipid} (PP)")
    plt.xlabel('Days since PP administration')
    plt.ylabel('Survival Probability')
    plt.legend()
    plt.savefig(f"KM_PP_{safe_lipid_name}.png", dpi=300, bbox_inches='tight')
    plt.show()

# Plot Kaplan-Meier curves for the CTRL group
def plot_km_for_ctrl(lipid):
    # Median split based on lipid concentration
    median_ctrl = ctrl_group[lipid].median()
    above_median_ctrl = ctrl_group[ctrl_group[lipid] > median_ctrl]
    below_median_ctrl = ctrl_group[ctrl_group[lipid] <= median_ctrl]
    
    # Perform log-rank test between above/below median groups
    results = logrank_test(above_median_ctrl['Number of days since PP administration'],
                           below_median_ctrl['Number of days since PP administration'],
                           event_observed_A=above_median_ctrl['Event'],
                           event_observed_B=below_median_ctrl['Event'])
    p_value_log = results.p_value
    
    # Plot survival curves
    kmf = KaplanMeierFitter()
    plt.figure(figsize=(8, 6))
    
    kmf.fit(above_median_ctrl['Number of days since PP administration'], event_observed=above_median_ctrl['Event'])
    kmf.plot(label='Above Median (CTRL)')
    
    kmf.fit(below_median_ctrl['Number of days since PP administration'], event_observed=below_median_ctrl['Event'])
    kmf.plot(label='Below Median (CTRL)')
    
    # Annotate with p-value
    plt.text(0.05, 0.05, f'Log-rank p-value: {p_value_log:.3f}', transform=plt.gca().transAxes,
             fontsize=9, bbox=dict(facecolor='white', alpha=0.7, edgecolor='black'))
    
    # Finalize plot
    plt.title(f"Survival Curve for {lipid} (CTRL)")
    plt.xlabel('Days since PP administration')
    plt.ylabel('Survival Probability')
    plt.legend()
    # You can uncomment the next line to save CTRL plots too
    # plt.savefig(f"KM_CTRL_{lipid}.png")
    plt.show()

# Run analysis for each lipid
for lipid in lipids:
    plot_km_for_pp(lipid)
    plot_km_for_ctrl(lipid)

# (Optional) Convert stat_results into DataFrame – currently unused
stat_results_df = pd.DataFrame(stat_results)

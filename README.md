## 🧬 Code-storage

This folder contains **Python** code and an **SQL** file.
Most of the files are related to projects carried out during my PhD. They relate to analyses associated with a mouse model of triple negative breast cancer (TNBC) and to a substance being tested as a potential drug: Pyrvinium Pamoate. 
> This is only a marginal part of the biostatistical analyses and visualisations that have been carried out.

---

## 📁 Repository Structure

    .
    ├── Python/
    │   ├── Additional_projects/
    │       ├── ML/
    │       └── Text_analysis/
    │   ├── Jupyter_Notebook/
    │   ├── Poster_session 2025/
    │       ├── Raw_code/
    │           └── Dash_Volcano_PT/
    │       └── Jupyter_Notebook/
    │   └──Raw_code/
    │
    ├── SQL/
    │   └── OPUS_BC.sql
    │
    ├── .gitignore
    ├── requirements.txt
    └── README.md
    
---

## 🔍 Content Overview

**Other Analyses**

This section contains additional scripts and notebooks supporting various analyses related to tumor biology and treatment effects in mouse models. These analyses complement the main poster work by exploring immune infiltration patterns, gene expression changes, tumor growth dynamics, and survival outcomes, as well as providing database queries for clinical material from TNBC patients.

- `Clustermap - 2 colourbars.*` — Heatmap/Clustermap for immune cell infiltration in tumours of Balb/c mice treated with Pyrvinium Pamoate.
- `SmartSeq cycle count comparison.*` — Scatter plot for qPCR Cq mean values in 4T1 and positive control samples.
- `Survival Curve Serum_separate median.*` — Survival analysis of mice based on PUFA serum levels.
- `Tumor Volume Changes Over Time.*` — Tumor volume dynamics in mice treated with Pyrvinium Pamoate (PP).
- `Volcano_plot_4T1.*` — Volcano plot for differential gene expression in 4T1 cells treated with Pyrvinium Pamoate.
- `OPUS_BC.sql` — SQL queries used to extract and preprocess data from the OPUS_BC database.


**Poster_session 2025**

This section contains scripts and Jupyter notebooks prepared for the 2025 poster presentation. The analyses focus on immune and pathological features in a TNBC mouse model, comparing control and treated groups.
Each pair of .py and .ipynb files corresponds to a specific analysis and visualization that were explored during poster preparation and formed the basis for selecting the final content.

🔬 Inflammation & Metastases in the Liver
- `Abscesses level_all mice_poster.*` — Percentage of mice with different levels of liver inflammation or neutrophilic inflammation (all mice).
- `Abscesses level_poster.*` — Same as above, limited to mice treated with Pyrvinium Pamoate (PP) for 9 days or more (excluding 311, 324, 335).
- `Macrometastases vs Micrometastases in the liver_all mice_poster.*` — Comparison of macro- and micrometastases (all mice).
- `Macrometastases vs Micrometastases in the liver_poster.*` — Same, filtered to mice treated with PP for 9 days or more (excluding 311, 324, 335).
- `Inflammation score vs Metastasis score_no311_nostatistics_poster.*` — Visualization of inflammation and metastasis scores excluding mouse no. 311, without statistical tests.

🔬 Primary Tumor Features
- `Cell Type_Necrosis in primary tumour.*` — Analysis of cell type and necrosis in primary tumors (Chi-square test + plots).
- `Cell Type_Necrosis in PT vs Liver metastases_abscesses_poster.*` — Relationships between tumor cell type, necrosis, liver metastases, and inflammation.

🔬 RNA-seq Analysis of Primary Tumors
- `Volcano plot_PT_day9_poster.*` — Volcano plot of differential gene expression in primary tumors after 9 or more days of treatment (RNA-seq data).
- `Volcano plot_PT_day9_excluded_genes_poster.*` — Volcano plot excluding selected genes for better clarity (RNA-seq data).
- `GO Enrichment_PT_Day9_poster.*` — Gene Ontology enrichment analysis for primary tumors treated for 9 or more days (RNA-seq data).

🔬 Infiltration Score
- `Clustermap with 2 colorbars_poster.*` — Clustermap of Z-scored immune cell abundances (ImmuCellAI-mouse output).
- `Clustermap with 2 colorbars_significance_poster.*` — Clustermap highlighting statistically significant differences between treated and control groups.
- `Infiltration vs Cell Type_Necrosis_poster.*` — Infiltration score by primary tumor cell type and necrosis status.
- `Infiltration vs Liver metastases_abscesses_poster.*` — Infiltration scores vs liver metastases and inflammation across groups.

**Additional_projects**

This section contains various Python projects, ranging from classic scripts and small games to machine learning and text analysis applications.

🤖 ML
- `Wine_classification.py` & `Wine_classification.ipynb` — Classification model and notebook applied to wine dataset analysis.

📝 Text Analysis
- `analyzer.py` — Core text analysis functionality.  
- `gui_text_analyzer.py` — Simple graphical interface for text analysis.  
- `input_text.txt` — Sample input text file.

🎮 Other Python Scripts
- `Bank_account.py` — Basic bank account management script.  
- `Simple_treasure_game.py` — A simple treasure hunt game implemented in Python.

---

## 🛠️ Technologies

- Python 3.10+
- JupyterLab
- Libraries: `pandas`, `seaborn`, `matplotlib`, `numpy`, `lifelines`, `scipy`
- SQL (PostgreSQL / MySQL depending on the environment)

---

## 📌 Project Status

The repository is actively being organized and updated. More scripts and documentation may be added over time.

---

## 📄 License

This repository is published for academic and educational purposes. Please cite or credit appropriately if used.

## 🧬 Code-storage

This folder contains **Python** code and an **SQL** file.
Most of the files are related to projects carried out during my PhD. They relate to analyses associated with a mouse model of triple negative breast cancer (TNBC) and to a substance being tested as a potential drug: Pyrvinium Pamoate. 
> This is only a marginal part of the biostatistical analyses and visualisations that have been carried out.

---

## 📁 Repository Structure

    .
    ├── Flutter/
    │   └── Woman_in_STEM.dart
    │ 
    ├── PowerBI&Tableau/
    │   ├── PowerBI/
    │       └── Employee Management Power BI Report.md
    │   ├── Tableau/
    │       └── Movies Analysis Tableau Report.md
    │ 
    ├── Python/
    │   ├── Additional_projects/
    │       ├── ML/
    │       └── Text_analysis/
    │   ├── Jupyter_Notebook/
    │   ├── Poster_session 2025/
    │       ├── Raw_code/
    │       └── Jupyter_Notebook/
    │   └──Raw_code/
    │       └── Dash_Volcano_PT/
    │
    ├── SQL/
    |   ├── Clinical_Trial/
    │   └── OPUS_BC.sql
    │
    ├── .gitignore
    ├── requirements.txt
    └── README.md
    
---

## 🔍 Content Overview

**SQL Projects**

This section contains SQL-based projects focused on database design, data integrity, access control, and analytical querying. The SQL work is independent of the biological analyses and is intended to demonstrate structured database development and querying skills.

- `SQL/Clinical_Trial/` — Complete PostgreSQL Clinical Trial database project, including conceptual and logical models, physical schema (DDL), sample data, PL/pgSQL functions and triggers, reporting views, role-based access control, optional Row-Level Security (RLS), and example analytical queries (CTEs, window functions, subqueries, QC checks).
- `OPUS_BC.sql` — SQL queries used to extract and preprocess clinical data from the OPUS_BC database (TNBC patient material).

**Dash_Volcano_PT (data & helper files)**
This subfolder contains data and helper scripts for generating volcano plots using RNA-seq results, intended for interactive use or app deployment.
- `Volcano plot_RNAseq_PT_by days.py` — Generates volcano plots of RNA-seq data stratified by treatment duration (days).
- `summary_table_supervised_PT_PP_PT_CTRL_and_PT_PP_PT_CTRL_long_7_9_12_230524.txt` — Summary table of differentially expressed genes comparing PP vs CTRL groups on days 7, 9, and 12.
- `requirements.txt` — List of Python libraries required to run the volcano plot pipeline or web app.
- `runtime.txt` — Environment configuration file (e.g., for Heroku deployments).

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

**Other Analyses**

This section contains additional scripts and notebooks supporting various analyses related to tumor biology and treatment effects in mouse models. These analyses complement the main poster work by exploring immune infiltration patterns, gene expression changes, tumor growth dynamics, and survival outcomes, as well as providing database queries for clinical material from TNBC patients.

- `Clustermap - 2 colourbars.*` — Heatmap/Clustermap for immune cell infiltration in tumours of Balb/c mice treated with Pyrvinium Pamoate.
- `Clustermap_lipids_PT_no311.*` - Clustermap for lipid content (%mol) in primary tumours of Balb/c mice treated with Pyrvinium Pamoate (without mouse no. 311).
- `Lipids_PT_no311.*` - Analysis of lipid levels in primary tumours (excluding mouse no. 311); includes box plots and statistical tests.
- `SmartSeq cycle count comparison.*` — Scatter plot for qPCR Cq mean values in 4T1 and positive control samples.
- `Survival Curve Serum_separate median.*` — Survival analysis of mice based on PUFA serum levels.
- `Tumor Volume Changes Over Time.*` — Tumor volume dynamics in mice treated with Pyrvinium Pamoate (PP).
- `Volcano_plot_4T1.*` — Volcano plot for differential gene expression in 4T1 cells treated with Pyrvinium Pamoate.
  
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

### 🗺️ Quick Folder Map

| **Folder path** | **Description** |
|-----------------|-----------------|
| `Python/Poster_session 2025/Jupyter_Notebook` | Jupyter notebooks created for the 2025 poster presentation. Each file corresponds to a specific analysis. |
| `Python/Poster_session 2025/Raw_code` | Matching Python scripts for each poster analysis notebook. Same filenames, clean code. |
| `Python/Jupyter_Notebook` | Independent exploratory notebooks not linked to the poster. Includes clustermaps, tumor volume trends, survival curves, etc. |
| `Python/Raw_code` | Helper scripts and standalone analyses (e.g. lipid profiling, 4T1 volcano plots) outside the poster scope. |
| `Python/Raw_code/Dash_Volcano_PT` | Data and scripts for volcano plot generation and app deployment (RNA-seq PT groups). |
| `Python/Additional_projects/ML` | Machine learning examples and models (e.g. wine classification task). |
| `Python/Additional_projects/Text_analysis` | Text processing utilities with both CLI and GUI interface. |
| `Python/Additional_projects` | Miscellaneous Python scripts, such as games or simulations. |
| `SQL/Clinical_Trial` | Complete PostgreSQL Clinical Trial database project: conceptual & logical models, physical schema (DDL), sample data, functions, triggers, views, roles & privileges, optional RLS, and analytical/QC queries. |
| `SQL/OPUS_BC.sql` | SQL queries for TNBC patient data extraction from the OPUS_BC database. |
| *(root)* | Shared files: `README.md`, `requirements.txt`, `.gitignore`, and structure snapshot `repo_structure.txt`. |

---
## 🛠️ Technologies

**Core technologies used in this repository:**
- Python 3.10+
- JupyterLab
- SQL (PostgreSQL; MySQL in selected environments)
- Libraries: `pandas`, `seaborn`, `matplotlib`, `numpy`, `lifelines`, `scipy`

**Additional tools & platforms (used in selected projects):**
- Flutter — mobile app development framework (Dart)
- Power BI — data visualization and business intelligence
- Tableau — interactive dashboards and visual analytics

---

## 📌 Project Status

The repository is actively maintained and periodically updated.
Individual projects may be considered complete, while documentation and structure continue to evolve.
---

## 📄 License

This repository is published for academic and educational purposes. Please cite or credit appropriately if used.

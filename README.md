## 🧬 Code-storage

This folder contains **Python** code and an **SQL** file.
Most of the files are related to projects carried out during my PhD. They relate to analyses associated with a mouse model of triple negative breast cancer (TNBC) and to a substance being tested as a potential drug: Pyrvinium Pamoate. 
> This is only a marginal part of the biostatistical analyses and visualisations that have been carried out.

---

## 📁 Repository Structure

    .
    ├── Python/
    │   ├── Raw_code/
    │   ├── Jupyter_Notebook/
    │   └── Poster_session 2025/
    │       ├── Raw_code/
    │       └── Jupyter_Notebook/
    │
    ├── SQL/
    │   └── OPUS_BC.sql
    │
    ├── .gitignore
    ├── requirements.txt
    └── README.md
    
---

## 🔍 Content Overview

- `Clustermap - 2 colourbars.py` & `Clustermap - 2 colorbars.ipynb` – Heatmap/Clustermap for Immune Cell Infiltration in Tumours of Balb/c Mice Treated with Pyrvinium Pamoate.
- `SmartSeq cycle count comparison.py` & `SmartSeq cycle count comparison.ipynb` - Scatter Plot for qPCR Cq Mean Values in 4T1 and Positive Control Samples.
- `Survival Curve Serum_separate median.py` & `Survival Curve Serum_separate median.ipynb` - Survival Analysis of Mice Based on PUFA Serum Levels.
- `Tumor Volume Changes Over Time.py` & `Tumor Volume Changes Over Time.ipynb` - Tumor Volume Dynamics in Mice with Pyrvinium Pamoate (PP) Administration.
- `Volcano_plot_4T1.py` & `Volcano_plot_4T1.ipynb` – Volcano Plot for Differential Gene Expression in 4T1 Cells Treated with Pyrvinium Pamoate.
- `OPUS_BC.sql` – SQL queries used to extract and preprocess data from the OPUS_BC database.

**Poster_session 2025**
- `Abscesses level_all mice_poster.py` & `Abscesses level_all mice_poster.ipynb` - Percentage of mice with different levels of liver abscesses/(neutrophile) inflammation across experimental groups (all mice).
- `Abscesses level_poster.py` & `Abscesses level_poster.ipynb` - Percentage of mice with different levels of liver abscesses/(neutrophile) inflammation across experimental groups (≥ 9, without no. 311, 324 & 335).
- `Cell Type_Necrosis in PT vs Liver metastasses_abscesses_poster.py` & `Cell Type_Necrosis in PT vs Liver metastasses_abscesses_poster.ipynb` - Visualization and statistical analysis of features of primary tumors in the TNBC mouse model (relationships between cell type, necrosis, liver metastases and liver abscesses).
- `Cell Type_Necrosis in primary tumour.py` & `Cell Type_Necrosis in primary tumour.ipynb` - Primary Tumor Cell Type and Necrosis Analysis with Chi-Square Test and Visualization.
- `Clustermap with 2 colorbars_poster.py` & `Clustermap with 2 colorbars_poster.ipynb` - Clustermap showing Z-scored immune cell abundances 
in mouse tumor samples (data derived from ImmuCellAI-mouse analysis).
- `Infiltration vs Cell Type_Necrosis_poster.py` & `Infiltration vs Cell Type_Necrosis_poster.ipynb` - Infiltration Score Analysis by Cell Type and Necrosis.
- `Infiltration vs Liver metastases_abscesses_poster.py` & `Infiltration vs Liver metastases_abscesses_poster.ipynb` - Visualization and statistical analysis of the relationship between immune cell infiltration (infiltration score) and two liver parameters: metastases and abscesses, across control and treated groups in a mouse model.
- `Macrometastases vs Micrometastases in the liver_all mice_poster.py` & `Macrometastases vs Micrometastases in the liver_all mice_poster.ipynb` - Comparison of Liver Metastases in Experimental Mouse Groups (all mice).
- `Macrometastases vs Micrometastases in the liver_poster.py` & `Macrometastases vs Micrometastases in the liver_poster.ipynb` - Comparison of Liver Metastases in Experimental Mouse Groups (≥ 9, without no. 311, 324 & 335).


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

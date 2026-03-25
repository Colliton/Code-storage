import pandas as pd


def process_file(input_file, output_file):
    df = pd.read_csv(input_file, sep=";", keep_default_na=False)

    df_small = (
        df.groupby("Country", group_keys=False)
          .apply(lambda x: x.sample(max(1, int(len(x) * 0.03)), random_state=42))
          .reset_index(drop=True)
    )

    df_small.to_csv(output_file, index=False)


process_file("source_EU_sample.csv", "source_EU_small.csv")
process_file("source_nonEU_sample.csv", "source_nonEU_small.csv")

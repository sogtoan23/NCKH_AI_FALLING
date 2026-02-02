import os
import pandas as pd
import numpy as np

# ================= CONFIG =================
RAW_DIR = "csv_output"
OUTPUT_FILE =  r"F:\Train AI\features\features.csv"

WINDOW_SIZE = 200      # samples (100 Hz → 2 giây)
STEP_SIZE   = 100      # overlap 50%

SENSOR_COLS = ['ax','ay','az','gx','gy','gz']

# ================= FEATURE FUNCTIONS =================
def extract_features(window):
    feats = {}
    for col in SENSOR_COLS:
        data = window[col].values
        feats[f'{col}_mean'] = np.mean(data)
        feats[f'{col}_std']  = np.std(data)
        feats[f'{col}_max']  = np.max(data)
        feats[f'{col}_min']  = np.min(data)
        feats[f'{col}_energy'] = np.sum(data**2) / len(data)
    return feats

# ================= MAIN =================
all_features = []

for file in os.listdir(RAW_DIR):
    if not file.endswith(".csv"):
        continue

    path = os.path.join(RAW_DIR, file)
    df = pd.read_csv(path)

    df = df.dropna()

    for start in range(0, len(df) - WINDOW_SIZE, STEP_SIZE):
        window = df.iloc[start:start + WINDOW_SIZE]

        feats = extract_features(window)

        # label: majority vote
        feats['label'] = int(window['label'].mode()[0])
        feats['activity'] = window['activity'].iloc[0]
        feats['subject']  = window['subject'].iloc[0]

        all_features.append(feats)

features_df = pd.DataFrame(all_features)
features_df.to_csv(OUTPUT_FILE, index=False)

print("✅ STEP C DONE")
print("Total windows:", len(features_df))
print("Saved:", OUTPUT_FILE)

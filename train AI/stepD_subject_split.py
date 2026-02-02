import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report
from sklearn.preprocessing import LabelEncoder
import joblib

# ================= CONFIG =================
FEATURE_FILE =  r"F:\Train AI\features\features.csv"
TEST_SUBJECT = None   # None = random split | ví dụ "esp32_01" nếu test ESP32

# ================= LOAD =================
df = pd.read_csv(FEATURE_FILE)

X = df.drop(columns=['label','activity','subject'])
y = df['label']

# Encode subject
le = LabelEncoder()
df['subject_enc'] = le.fit_transform(df['subject'])

# ================= SPLIT =================
if TEST_SUBJECT is not None:
    test_mask = df['subject'] == TEST_SUBJECT
    X_train = X[~test_mask]
    y_train = y[~test_mask]
    X_test  = X[test_mask]
    y_test  = y[test_mask]
else:
    from sklearn.model_selection import train_test_split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

# ================= TRAIN =================
model = RandomForestClassifier(
    n_estimators=200,
    max_depth=None,
    class_weight='balanced',
    random_state=42
)

model.fit(X_train, y_train)

# ================= EVAL =================
y_pred = model.predict(X_test)

print("\nAccuracy:", accuracy_score(y_test, y_pred))
print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))

print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# ================= SAVE =================
joblib.dump(model, "fall_detection_rf.pkl")
print("\n✅ Model saved as fall_detection_rf.pkl")

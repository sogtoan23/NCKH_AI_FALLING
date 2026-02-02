from flask import Flask, request
import os

app = Flask(__name__)

OUTPUT_DIR = r"F:\Train AI\Test AI\output"
OUT_FILE = os.path.join(OUTPUT_DIR, "esp32_test_raw.csv")

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Header CHUẨN TRAIN AI
if not os.path.exists(OUT_FILE):
    with open(OUT_FILE, "w") as f:
        f.write(
            "timestamp,ax,ay,az,gx,gy,gz,label,activity,subject\n"
        )

@app.route("/data", methods=["POST"])
def receive_data():
    line = request.data.decode("utf-8").strip()
    if line:
        with open(OUT_FILE, "a") as f:
            f.write(line + "\n")
    return "OK", 200

if __name__ == "__main__":
    print("Server running")
    print("Saving to:", OUT_FILE)
    app.run(host="0.0.0.0", port=5000)

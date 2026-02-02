#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <SparkFunLSM6DS3.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ================= WIFI =================
const char* WIFI_SSID = "YOUR_WIFI";
const char* WIFI_PASS = "YOUR_PASS";
const char* SERVER_URL = "http://192.168.1.100:5000/data";

// ================= SUBJECT =================
const char* SUBJECT = "esp32_01";

// ================= OLED =================
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// ================= BUTTON =================
#define BTN_PIN 12   // 1 nút duy nhất

// ================= IMU =================
LSM6DS3 imu(I2C_MODE, 0x6A);

// ================= SAMPLE =================
unsigned long lastSample = 0;
const int SAMPLE_RATE_MS = 10; // 100 Hz
unsigned long startTime;

// ================= MODE =================
const char* modes[]      = {"WALK", "STAND", "SIT", "FALL"};
const char* activities[] = {"walk", "stand", "sit", "fall"};
const int labels[]       = {0, 0, 0, 1};
const int MODE_COUNT = 4;

int modeIndex = 0;
bool sending = false;

// ================= BUTTON STATE =================
bool lastBtnState = HIGH;
unsigned long pressTime = 0;
bool longPressHandled = false;

// ================= SETUP =================
void setup() {
  Serial.begin(115200);
  Wire.begin();

  pinMode(BTN_PIN, INPUT_PULLUP);

  // OLED
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // IMU
  if (imu.begin() != 0) {
    showMessage("IMU ERROR");
    while (1);
  }

  // WIFI
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  showMessage("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
  }

  showMode();
  startTime = millis();
}

// ================= LOOP =================
void loop() {
  handleButton();

  if (sending && millis() - lastSample >= SAMPLE_RATE_MS) {
    lastSample = millis();
    sendIMU();
  }
}

// ================= BUTTON LOGIC =================
void handleButton() {
  bool btnState = digitalRead(BTN_PIN);

  // Nhấn xuống
  if (btnState == LOW && lastBtnState == HIGH) {
    pressTime = millis();
    longPressHandled = false;
  }

  // Giữ nút
  if (btnState == LOW && !longPressHandled) {
    if (millis() - pressTime >= 3000) { // 3 giây
      sending = !sending;  // START / STOP
      longPressHandled = true;
      showMode();
    }
  }

  // Nhả nút
  if (btnState == HIGH && lastBtnState == LOW) {
    if (!longPressHandled) {
      // Nhấn ngắn → đổi mode
      modeIndex = (modeIndex + 1) % MODE_COUNT;
      showMode();
    }
  }

  lastBtnState = btnState;
}

// ================= SEND IMU =================
void sendIMU() {
  float ax = imu.readFloatAccelX();
  float ay = imu.readFloatAccelY();
  float az = imu.readFloatAccelZ();

  float gx = imu.readFloatGyroX();
  float gy = imu.readFloatGyroY();
  float gz = imu.readFloatGyroZ();

  float timestamp = (millis() - startTime) / 1000.0;

  String csv =
    String(timestamp,3) + "," +
    String(ax,4) + "," +
    String(ay,4) + "," +
    String(az,4) + "," +
    String(gx,4) + "," +
    String(gy,4) + "," +
    String(gz,4) + "," +
    String(labels[modeIndex]) + "," +
    String(activities[modeIndex]) + "," +
    String(SUBJECT);

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(SERVER_URL);
    http.addHeader("Content-Type", "text/plain");
    http.POST(csv);
    http.end();
  }
}

// ================= OLED DISPLAY =================
void showMode() {
  display.clearDisplay();

  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("MODE:");

  display.setTextSize(2);
  display.setCursor(0, 16);
  display.println(modes[modeIndex]);

  display.setTextSize(1);
  display.setCursor(0, 48);
  display.println(sending ? "SENDING..." : "PAUSED");

  display.display();
}

void showMessage(const char* msg) {
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(0, 20);
  display.println(msg);
  display.display();
}

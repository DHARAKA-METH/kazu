# 🐾 Project Kazu – Smart Pet Tracking IoT Device + Mobile App

**Project Kazu** is an **IoT device + mobile app** that helps pet owners track their pets in real time.  
Using a GPS-enabled device connected to the app, Kazu provides **live location updates**, **safety alerts**, and easy monitoring to keep pets safe at all times.

---

## 🐶 Features

- **Real-Time Pet Tracking** – Check your pet’s live location anytime via the mobile app.  
- **Pet Status Monitoring** – View your pet’s current activity and condition.  
- **Safe Zone Definition** – Set safe zones for your pets directly from the app.  
- **Alerts & Notifications** – Receive instant alerts when a pet enters or leaves a safe zone.  
- **Vibration/Buzzer Alerts** – The IoT device buzzes if the pet moves outside the safe zone.  

---


## 🛠️ Tech Stack

### **📱 Mobile App (Flutter)**
- **Flutter** (Dart)
- **Google Maps SDK**
- **HTTP / MQTT client packages**
- **Firebase Auth**
- **Firebase Database (Realtime and Firestore)**

## 🏗 Architecture




        +------------------+
        |   IoT Device     |
        |  (GPS + Sensors) |
        |                  |
        | - Tracks pet     |
        | - Sends data     |
        +--------+---------+
                 |
                 | MQTT Publish (location, status, alerts)
                 |
        +--------v---------+
        |    MQTT Broker   |
        +--------+---------+
                 |
                 | MQTT Subscribe / Firebase Sync
                 |
        +--------v------------------+
        | Mobile App (Flutter)      |
        |                           |
        | - Shows real-time location|
        | - Displays pet status     |
        | - Sets safe zones         |
        | - Receives alerts         |
        +--------------------------+



---

##  Screenshots


---
![3 2](https://github.com/user-attachments/assets/60b453ad-41e8-4a68-bce6-06db76a76044)
![1](https://github.com/user-attachments/assets/fbac07c9-14a5-44f2-961c-21b74b62a09e)
<img width="423" height="868" alt="Screenshot 2025-12-08 103958" src="https://github.com/user-attachments/assets/dc717dc1-65fe-4ae1-b6e3-9a9fdfa5eb63" />


---

## ⚙️ Installation

###  Install Flutter

Follow the official Flutter installation guide: [Flutter Install](https://flutter.dev/docs/get-started/install)

Verify installation:

```bash
flutter doctor
```

##  Configure key.properties

#### Create a file named key.properties in the android/ folder of your Flutter project:

# Location of Android SDK
sdk.dir=C:\\Users\\MSI\\AppData\\Local\\Android\\sdk

```

# Flutter SDK path
flutter.sdk=C:\\flutter

# App build mode
flutter.buildMode=debug

# App version
flutter.versionName=1.0.0
flutter.versionCode=1

# Google Maps API Key
MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY //Replace YOUR_GOOGLE_MAPS_API_KEY with your own API key.

```

## Run the App
Get dependencies:

```bash
flutter pub get
```
Run on emulator or connected device:
```bash
flutter run
```

## 📥 Download and Try App

You can try **Project Kazu** using the sample account below:  

**Download the APK here:** [Project Kazu APK](https://drive.google.com/file/d/1BY2VADvYi4-hqKOd17M-FuLwdahqAGJI/view?usp=sharing)

**Demo Login Credentials:**
- **Email:** `team19@gmail.com`  
- **Password:** `team19@gmail.com`

> ⚠️ This is a demo account for testing purposes only.






# Smart Home Premium Controller 🏠📱

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org)
[![Bluetooth](https://img.shields.io/badge/Bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white)](https://www.bluetooth.com)

A professional, high-performance smart home control application built with Flutter. Featuring a stunning **Glassmorphism UI** and a robust **Bluetooth SPP (Serial Port Profile) synchronization engine**, this app provides a seamless interface between your mobile device and hardware (ESP32, Arduino, or Linux servers).

---

## 🌟 Key Features

- **Universal Sync Engine**: Automatically synchronizes app state with hardware signals in real-time.
- **Dynamic Device Engine**: Add and configure any hardware device (LEDs, Fans, Doors, etc.) without changing a single line of code.
- **Glassmorphism Design**: A premium, modern dark-themed UI with vibrant gradients and smooth micro-animations.
- **Diagnostic Terminal**: A real-time log for monitoring all incoming and outgoing Bluetooth traffic for debugging.
- **State Persistence**: Remembers your device configurations and favorite toggles across sessions.

---

## 🚀 Getting Started

### 📋 Requirements

- **Mobile**: Android 7.0+ (Optimized for Android 14).
- **Hardware**: Any Bluetooth Classic enabled device (ESP32, HC-05, or a Linux PC).
- **Development**: Flutter SDK installed on your machine.

### 🏃 Running the Application

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Controller
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run in Debug Mode**:
   ```bash
   flutter run
   ```

---

## 🛠 Dynamic Mapping Guide

The core power of this app lies in its ability to map generic Bluetooth signals to UI actions. When adding a device, you define:

1. **Commands (App ➡️ Hardware)**: What the app sends when you toggle a button (e.g., `a` for ON, `A` for OFF).
2. **Responses (Hardware ➡️ App)**: What the hardware sends back to update the UI state (e.g., `L1_ON` for ON, `L1_OFF` for OFF).

This allows the app to stay in perfect sync even if the hardware state changes physically (via a manual button).

---

## 🧪 Testing with the SPP Simulator

To test the application without physical hardware, use the provided **Python SPP Simulator** located in the `tools/spp_server/` directory.

See the [SPP Server README](tools/spp_server/README.md) for detailed instructions on how to set up a virtual hardware environment on Linux.

---

**Developed for high-fidelity smart home automation.**

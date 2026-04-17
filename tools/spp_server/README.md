# Bluetooth SPP Simulator 📡

This directory contains a Python-based **Bluetooth Serial Port Profile (SPP)** simulator. It allows you to emulate a physical hardware device (like an ESP32) on your Linux machine, enabling full end-to-end testing of the Smart Home Controller app without needing physical hardware.

---

## 🚀 Features

- **Standard SPP Advertisement**: Uses BlueZ to advertise the standard Serial Port service.
- **Interactive Mode**: Real-time terminal where you can manually send signals to the app (e.g., `L1_ON`, `FAN_OFF`).
- **Signal Logging**: Automatically logs all commands received from the Flutter app.
- **Auto-Ready**: Sends a `READY` handshake signal upon connection to confirm the link is active.

---

## 📋 Prerequisites (Linux)

To run the simulator, you need a Linux machine with a Bluetooth adapter and the following dependencies:

1. **System Dependencies**:
   ```bash
   sudo apt-get install python3-dev libbluetooth-dev bluez bluetooth
   ```

2. **Python Package**:
   ```bash
   pip install pybluez2
   ```

3. **Bluetooth Configuration**:
   Ensure your adapter is discoverable:
   ```bash
   bluetoothctl
   # Inside bluetoothctl:
   power on
   discoverable on
   pairable on
   ```

---

## 🏃 Usage

### Running the Interactive Server

The interactive server is the recommended way to test. It allows you to see what the app sends and manually reply to trigger UI changes.

```bash
# From the project root
python3 tools/spp_server/interactive_server.py --name "SmartHome-Simulator"
```

### Command Map Examples

While the server is running, you can type responses manually in the terminal. Here are common examples used by the app's default configuration:

| Feature | App Sends | You Send Back |
|---------|-----------|---------------|
| **LED 1** | `a` (ON) / `A` (OFF) | `L1_ON` / `L1_OFF` |
| **Fan** | `f` (ON) / `F` (OFF) | `FAN_ON` / `FAN_OFF` |
| **Door** | `X` (OPEN) / `O` (CLOSE) | `DOOR_OPEN` / `DOOR_CLOSE` |
| **Laundry Rack**| `R0` / `R1` / `R2` | `RACK_0` / `RACK_90` / `RACK_180` |

---

## 🛠 Advanced Options

- `--name`: Change the Bluetooth broadcast name (default: "SmartHome-SPP-Test").
- `--channel`: Specify the RFCOMM channel (default: 1).
- `--no-ready`: Disable the initial "READY" message.
- `--native`: Attempt to use native Linux AF_BLUETOOTH sockets instead of pybluez.

---

**Note**: You must pair your mobile device with your Linux machine through the system settings before the app can detect and connect to the simulator.

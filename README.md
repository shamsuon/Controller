<div align="center">
  <img src="assets/images/controller_logo.png" alt="Smart Home Controller logo" width="180">

  # Smart Home Controller

  **Control and monitor Bluetooth-enabled smart-home devices from one Flutter app.**

  [![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://www.android.com/)
  [![Bluetooth](https://img.shields.io/badge/Connectivity-Bluetooth%20Classic-0082FC?logo=bluetooth&logoColor=white)](https://www.bluetooth.com/)
</div>

---

## Project video

Watch the app introduction:

[▶️ Play Smart Home Controller — Motion Graphics](assets/video/Smart_Home_Controller_Motion_Graphics.mp4)

> The video is included in this repository at `assets/video/Smart_Home_Controller_Motion_Graphics.mp4`.

## About

Smart Home Controller is an Android app built with Flutter for communicating with smart-home hardware over Bluetooth Classic Serial Port Profile (SPP). Pair with a compatible controller—such as an ESP32, HC-05, or a Linux SPP server—and configure devices with the commands and responses used by your hardware.

## Features

- **Flexible device controls:** configure toggle, trigger, and slider-style controls for your devices.
- **Device categories and favorites:** organize devices across categories such as lights, doors, fans, security, and tools.
- **Bluetooth SPP connection:** discover and connect to paired Bluetooth Classic devices, with reconnection to the last device.
- **Two-way state updates:** send commands to your controller and process incoming messages to keep device states in sync.
- **Built-in terminal:** inspect sent and received Bluetooth messages while testing or troubleshooting.
- **Local persistence:** keep device configuration and app data on the device.
- **Specialized controls:** includes support for door locks, RFID door locks, and adjustable rack devices.

## Requirements

- Flutter SDK compatible with the version in [`pubspec.yaml`](pubspec.yaml).
- An Android device or emulator; Bluetooth SPP features require a compatible Bluetooth Classic device.
- For hardware-free testing, a Linux computer with Bluetooth and the included SPP simulator.

## Getting started

1. Clone the repository and enter the project directory:

   ```bash
   git clone https://github.com/shamsuon/Controller.git
   cd Controller
   ```

2. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

3. Connect an Android device (or start an emulator) and run the app:

   ```bash
   flutter run
   ```

4. On a physical device, pair it with your Bluetooth controller in Android settings. Grant the Bluetooth permissions requested by the app, then discover and connect to the controller.

## Configure a device

When adding a device, provide the commands that your hardware expects and the response messages it sends back. For example:

| Action | Command sent by the app | Example response from hardware |
| --- | --- | --- |
| Turn a light on/off | `a` / `A` | `L1_ON` / `L1_OFF` |
| Turn a fan on/off | `f` / `F` | `FAN_ON` / `FAN_OFF` |
| Open/close a door | `X` / `O` | `DOOR_OPEN` / `DOOR_CLOSE` |
| Set rack position | `R0` / `R1` / `R2` | `RACK_0` / `RACK_90` / `RACK_180` |

These are example mappings from the simulator documentation. Configure commands to match your own hardware protocol.

## Test with the Bluetooth simulator

The Python SPP simulator can act as Bluetooth hardware for end-to-end testing. It requires Linux, a Bluetooth adapter, BlueZ, and `pybluez2`.

See the [simulator README](tools/spp_server/README.md) for setup instructions. To start its interactive server from the repository root:

```bash
python3 tools/spp_server/interactive_server.py --name "SmartHome-Simulator"
```

Pair your Android device with the Linux computer before connecting from the app.

## Project structure

```text
lib/                  Flutter app, screens, services, models, and widgets
assets/images/        App logos
assets/video/         Project video
tools/spp_server/     Bluetooth SPP simulator and documentation
```

## License

No license is currently specified for this repository. Contact the repository owner before redistributing or reusing the project.

# [SmartHome ELIAS](https://github.com/Hass090/SmartHome_ELIAS) (Mobile Application)

The official cross-platform mobile client for the **SmartHome ELIAS** ecosystem. Built using **Flutter**...

The official cross-platform mobile client for the **SmartHome ELIAS** ecosystem. Built using **Flutter**, this application provides full remote control, real-time telemetry monitoring, and secure management of your home automation grid.

## Features
* **Live Telemetry:** Real-time updates for temperature, humidity, and atmospheric pressure using MQTT.
* **Perimeter Management:** Virtual door lock actuators with instant state sync.
* **Interactive Climate Control:** Overriding environmental fan automation loops using manual toggles.
* **Security Feeds:** Instant push notifications for breaches or authorization logs powered by **Firebase Cloud Messaging (FCM)**.
* **Historical Logs:** Filterable timeline cards pulling critical event data from the central API.

## Tech Stack
* **Framework:** Flutter (Dart)
* **State Management:** Provider
* **Networking:** MQTT (via `mqtt_client`) & HTTP REST API
* **Notifications:** Firebase Messaging (FCM) & Local Notifications

## Installation & Setup
1. **Firebase Config:** Run FlutterFire CLI or drop your generated `google-services.json` into the android app directory.
2. **API Endpoint:** Update the target IP address (`192.168.1.25`) in `mqtt_service.dart` and HTTP clients to match your server host.
3. **Run Application:** Execute `flutter pub get` followed by `flutter run`.

## License
This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. 

### What this means:
* **Open Source Co-existence:** Any forks, modifications, or UI variations of this mobile application must remain open-source under the exact same GPL-3.0 license terms.
* **No Proprietary Paywalls:** You cannot repackage this app into a closed commercial product on the App Store or Google Play without making your full source code available to the users.
* **Attribution:** Original work must be credited to the original developer (**Hass**).

See the [LICENSE](LICENSE) file for the full text.

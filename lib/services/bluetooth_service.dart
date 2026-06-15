import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<void> startAdvertising(String data) async {
    // Note: Standard Flutter Blue Plus primarily handles scanning/connecting.
    // Advertising usually requires a different plugin like flutter_ble_peripheral
    // or custom platform channels. For this demo, we simulate discovery.
    print('Simulating BLE Advertising: $data');
  }

  Future<void> scanForPaypointDevices(Function(String) onFound) async {
    if (await FlutterBluePlus.isSupported == false) {
      print('Bluetooth not supported');
      return;
    }

    // Start scanning
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Look for PAYPOINT in device name or manufacturer data
        if (r.device.platformName.contains('PAPO_')) {
          onFound(r.device.platformName.replaceFirst('PAPO_', ''));
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }
}

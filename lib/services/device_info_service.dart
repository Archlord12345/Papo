import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  String? _deviceName;

  Future<String> getDeviceName() async {
    if (_deviceName != null) {
      return _deviceName!;
    }

    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      _deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      _deviceName = iosInfo.utsname.machine;
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfoPlugin.windowsInfo;
      _deviceName = windowsInfo.computerName;
    } else if (Platform.isMacOS) {
      final macosInfo = await deviceInfoPlugin.macOsInfo;
      _deviceName = macosInfo.computerName;
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfoPlugin.linuxInfo;
      _deviceName = linuxInfo.prettyName;
    } else {
      _deviceName = 'Unknown Device';
    }

    return _deviceName!;
  }
}

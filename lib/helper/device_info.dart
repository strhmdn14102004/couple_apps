import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceInfoService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveDeviceInfoToFirestore() async {
    try {
      // Get battery info
      Battery battery = Battery();
      int batteryLevel = await battery.batteryLevel;

      // Get network info
      var connectivityResult = await (Connectivity().checkConnectivity());
      String networkType = connectivityResult == ConnectivityResult.mobile
          ? "Mobile Data"
          : connectivityResult == ConnectivityResult.wifi
              ? "WiFi"
              : "None";

      // Get device info
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String deviceModel = androidInfo.model;

      // Get current user ID
      User? user = _auth.currentUser;
      String userId = user!.uid;

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'battery': batteryLevel,
        'network': networkType,
        'deviceModel': deviceModel,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving device info: $e");
    }
  }
}

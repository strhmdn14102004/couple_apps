// ignore_for_file: use_build_context_synchronously, cascade_invocations, always_specify_types, depend_on_referenced_packages, avoid_print

import "dart:convert";
import "dart:io";

import "package:crypto/crypto.dart" as crypto;
import "package:device_info/device_info.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:couple_app/helper/dialogs.dart";
import "package:couple_app/helper/navigators.dart";
import "package:url_launcher/url_launcher_string.dart";

class Generals {
  static Future<void> launchUrls(String url) async {
    try {
      if (!await launchUrlString(
        url,
        mode: LaunchMode.externalNonBrowserApplication,
      )) {
        throw Exception("Could not launch $url");
      }
    } catch (e) {
      BuildContext? buildContext = Navigators.navigatorState.currentContext;

      if (buildContext != null) {
        Dialogs.message(
          buildContext: buildContext,
          title: "Error!",
          message: e.toString(),
        );
      }
    }
  }

  static String sha1(String? data) {
    if (data != null) {
      List<int> encode = utf8.encode(data);

      return crypto.sha1.convert(encode).toString();
    }

    return "";
  }

  static String sha256(String? data) {
    if (data != null) {
      List<int> encode = utf8.encode(data);

      return crypto.sha256.convert(encode).toString();
    }

    return "";
  }

  static String md5(String? data) {
    if (data != null) {
      List<int> encode = utf8.encode(data);

      return crypto.md5.convert(encode).toString();
    }

    return "";
  }

  static Future<String> appVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo.version;
  }

  static Future<String> deviceId() async {
    if (kReleaseMode) {
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isIOS) {
        return "0000000000000000";
      } else {
        AndroidDeviceInfo androidDeviceInfo =
            await deviceInfoPlugin.androidInfo;

        return androidDeviceInfo.androidId.toString();
      }
    } else {
      return "5f3518db7a7ea6c6";
    }
  }
}

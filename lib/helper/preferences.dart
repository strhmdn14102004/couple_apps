// ignore_for_file: always_declare_return_types, always_specify_types

import "package:couple_app/constant.dart";
import "package:shared_preferences/shared_preferences.dart";

class Preferences {
  static Preferences? _instance;

  Preferences._internal();

  static Preferences getInstance() {
    _instance ??= Preferences._internal();

    return _instance!;
  }

  late SharedPreferences sharedPreferences;

  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  bool? getBool(SharedPreferenceKey sharedPreferenceKey, [bool? defValue]) {
    return sharedPreferences.getBool(sharedPreferenceKey.name) ?? defValue;
  }

  int? getInt(SharedPreferenceKey sharedPreferenceKey, [int? defValue]) {
    return sharedPreferences.getInt(sharedPreferenceKey.name) ?? defValue;
  }

  double? getDouble(SharedPreferenceKey sharedPreferenceKey, [double? defValue]) {
    return sharedPreferences.getDouble(sharedPreferenceKey.name) ?? defValue;
  }

  String? getString(SharedPreferenceKey sharedPreferenceKey, [String? defValue]) {
    return sharedPreferences.getString(sharedPreferenceKey.name) ?? defValue;
  }

  List<String>? getStrings(SharedPreferenceKey sharedPreferenceKey, [List<String>? defValue]) {
    return sharedPreferences.getStringList(sharedPreferenceKey.name) ?? defValue;
  }

  Future<void> setBool(SharedPreferenceKey sharedPreferenceKey, bool? value) async {
    if (value != null) {
      await sharedPreferences.setBool(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setInt(SharedPreferenceKey sharedPreferenceKey, int? value) async {
    if (value != null) {
      await sharedPreferences.setInt(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setDouble(SharedPreferenceKey sharedPreferenceKey, double? value) async {
    if (value != null) {
      await sharedPreferences.setDouble(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setString(SharedPreferenceKey sharedPreferenceKey, String? value) async {
    if (value != null) {
      await sharedPreferences.setString(sharedPreferenceKey.name, value);
    }
  }

  Future<void> setStrings(SharedPreferenceKey sharedPreferenceKey, List<String>? value) async {
    if (value != null) {
      await sharedPreferences.setStringList(sharedPreferenceKey.name, value);
    }
  }

  Future<void> remove(SharedPreferenceKey sharedPreferenceKey) async {
    await sharedPreferences.remove(sharedPreferenceKey.name);
  }

  bool contain(SharedPreferenceKey sharedPreferenceKey) {
    return sharedPreferences.containsKey(sharedPreferenceKey.name);
  }

  Future<void> clear() async {
    await sharedPreferences.clear();
  }

  Future<void> reload() async {
    await sharedPreferences.reload();
  }
}

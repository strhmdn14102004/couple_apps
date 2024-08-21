// ignore_for_file: non_constant_identifier_names, constant_identifier_names

class Parameter {
  static const bool API_PRINT_LOGGING_ENABLED = true;
  static const String SALT = "1234567890";
}

class ApiUrl {
  static String MAIN_BASE = "";
  static String SECONDARY_BASE = "";
  static String Mentahan = "";
}

enum SharedPreferenceKey {
  SESSION_ID,
  LAST_SYNC,
}

enum ScannerWordCase {
  UPPER_CASE,
  LOWER_CASE,
  NORMAL_CASE;

  String spell() {
    if (this == ScannerWordCase.NORMAL_CASE) {
      return "Normal Case";
    } else if (this == ScannerWordCase.UPPER_CASE) {
      return "UPPER CASE";
    } else {
      return "lower case";
    }
  }
}

enum activityHistory {
  SIGN_IN,
  SIGN_OUT,
}

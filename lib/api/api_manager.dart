// ignore_for_file: cascade_invocations, always_specify_types, avoid_print, non_constant_identifier_names, depend_on_referenced_packages

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:dio/io.dart";


import "package:couple_app/constant.dart";

class ApiManager {          
  static bool PRIMARY = true;

  static Future<Dio> getDio({
    bool plain = false,
  }) async {
    String baseUrl;

    if (PRIMARY) {
      baseUrl = ApiUrl.MAIN_BASE;
    } else {
      baseUrl = ApiUrl.SECONDARY_BASE;
    }

    Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseDecoder: (responseBytes, options, responseBody) {
          if (plain) {
            options.responseType = ResponseType.plain;
          }

          return utf8.decode(responseBytes, allowMalformed: true);
        },
      ),
    );


    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));


    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      HttpClient httpClient = HttpClient();

      httpClient.badCertificateCallback = (cert, host, port) => true;

      return httpClient;
    };

    return dio;
  }

  Future<Uint8List> download({
    required String url,
  }) async {
    Response response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));

    return response.data;
  }

}
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Map<String, dynamic> _parseAndDecode(String response) {
  return jsonDecode(response) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> parseJson(String text) {
  return compute(_parseAndDecode, text);
}

class HttpApi {

  String baseServer;
  late Dio dio;
  late Function _logout;

  HttpApi({
    required this.baseServer,
    required String key,
    required String deviceId,
  }) {
    dio = Dio(
        BaseOptions(
            baseUrl: baseServer,
            headers: {
              "X-API-KEY":key,
              "X-App-User":deviceId
            },
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
        )
    )
      ..interceptors.add(LogInterceptor(responseBody: true,requestBody: true,responseHeader: false,requestHeader: true))
      ..transformer = BackgroundTransformer();
  }

  setLogout(Function() logout) {
    _logout = logout;
  }


  setToken(String token) {
    if(token.isEmpty){
      dio.options.headers = {};
    } else {
      dio.options.headers = {"Auth":"$token"};
    }

  }


  Future<HttpApiResponse> get({
    required String patch,
    Map<String, dynamic> data = const {},
    CancelToken? cancelToken
  }) async {

    try {
      var resp = await dio.get(patch,queryParameters:data, cancelToken: cancelToken);
      return mapResponse(resp);
    } on DioException catch(e) {
      return mapException(e);
    } on Exception catch(e) {
      return mapInetException(e);
    }
  }

  Future<HttpApiResponse> post({
    required String patch,
    Map<String, dynamic> data = const {},
    CancelToken? cancelToken,
  }) async {

    try {
      var resp = await dio.post(patch,
          data: data,
          cancelToken: cancelToken,
          options: Options(contentType: Headers.formUrlEncodedContentType)
      );
      return mapResponse(resp);
    } on DioException catch(e) {
      return await mapException(e);
    } on Exception catch(e) {
      return mapInetException(e);
    }
  }

  Future<HttpApiResponse> put({
    required String patch,
    Map<String, dynamic> data = const {},
    CancelToken? cancelToken,
  }) async {

    try {
      var resp = await dio.put(patch,
          data: data,
          cancelToken: cancelToken,
          options: Options(contentType: Headers.formUrlEncodedContentType)
      );
      return mapResponse(resp);
    } on DioException catch(e) {
      return await mapException(e);
    } on Exception catch(e) {
      return mapInetException(e);
    }
  }

  Future<HttpApiResponse> postFile({
    required String patch,
    required FormData data,
    CancelToken? cancelToken,
  }) async {

    try {
      var resp = await dio.post(patch,
          data: data,
          cancelToken: cancelToken,
          options: Options(contentType: Headers.formUrlEncodedContentType)
      );
      return mapResponse(resp);
    } on DioException catch(e) {
      return await mapException(e);
    } on Exception catch(e) {
      return mapInetException(e);
    }
  }


  HttpApiResponse mapResponse(Response resp) {
    HttpApiResponse response = HttpApiResponse();
    response.code = resp.statusCode ?? 100;
    response.data = resp.data;

    return  response;
  }

  Future<HttpApiResponse> mapException(DioException e,) async {
    HttpApiResponse response = HttpApiResponse();
    response.isCanceled = CancelToken.isCancel(e);
    if (e.response != null) {
      int code = e.response!.statusCode ?? -1;
      if(code >= 400 && code <= 500) {
        response.data = e.response!.data;
      }

      if(code == 401) {
        _logout();
      }

      response.code = code;

    } else {
      response.code = -1;
    }
    print("code ${e.error}");
    response.errorMessage = e.message ?? e.error?.toString() ?? "Error load data. Check internet connection";
    return  response;
  }

  Future<HttpApiResponse> mapInetException(Exception e) async {
    HttpApiResponse response = HttpApiResponse();
    print("code $e");
    response.code = -1;
    response.errorMessage = e.toString();
    return  response;
  }



}

class HttpApiResponse {
  int code;
  bool isCanceled;
  dynamic data;
  String errorMessage;

  HttpApiResponse({
    this.code = 1,
    this.isCanceled = false,
    this.data,
    this.errorMessage = "",
  });
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

final connectivityProvider = StreamProvider((ref) {
  return ref.watch(networkControllerProvider).checkInternetConnection();
});

final networkControllerProvider = Provider((ref) {
  return NetworkController();
});

class NetworkController {
  NetworkController();

  Stream<bool> checkInternetConnection() async* {
    while (true) {
      bool isConnected = await _pingWebsite('https://www.google.com');
      yield isConnected;
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<bool> _pingWebsite(String url) async {
    try {
      Logger().d('Reach here 1');
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));

      final response = await dio.get(url);
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return false;
      } else if (e.type == DioExceptionType.unknown) {
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}

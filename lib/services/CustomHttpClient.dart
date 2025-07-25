import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class CustomHttpClient {
  static http.Client createUnsafeClient() {
    final ioClient =
        HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;

    return IOClient(ioClient);
  }
}

import 'dart:io';
import 'package:flutter/services.dart';

import 'log.dart';

void configHttpClient(Map<String, String>? proxy, bool? useSystemProxy) {
  log("useSystemProxy $useSystemProxy, proxy $proxy");
  if (useSystemProxy == true && proxy != null && proxy['host'] != null && proxy['port'] != null) {
    HttpOverrides.global = HttpProxy(proxy['host'], proxy['port']);
  } else {
    HttpOverrides.global = HttpProxy(null, null);
  }
}

class HttpProxy extends HttpOverrides {
  String? host;
  String? port;

  HttpProxy(this.host, this.port);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    var client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true;
    };
    return client;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    if (host == null || port == null) {
      return super.findProxyFromEnvironment(url, environment);
    }

    environment ??= {};
    environment['http_proxy'] = '$host:$port';
    environment['https_proxy'] = '$host:$port';
    environment['no_proxy'] = 'localhost,127.0.0.1';
    return super.findProxyFromEnvironment(url, environment);
  }
}

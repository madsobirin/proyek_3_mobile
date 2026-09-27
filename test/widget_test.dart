import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlife/main.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('FitLifeApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    await tester.pumpWidget(const FitLifeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FitLifeApp), findsOneWidget);
  });
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  set connectionFactory(dynamic f) {}
  @override
  set keyLog(dynamic callback) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}
  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> putUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> headUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> put(String host, int port, String path) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async =>
      _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) async =>
      _MockHttpClientRequest();
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  bool bufferOutput = false;
  @override
  int contentLength = 0;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = false;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  Future<HttpClientResponse> get done async => _MockHttpClientResponse();
  @override
  Future flush() async {}
  @override
  String get method => 'GET';
  @override
  Uri get uri => Uri.parse('http://localhost');
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void clear() {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  void noFolding(String name) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  String? value(String name) => null;
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = 0;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = false;
  @override
  int? port;
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static const List<int> _kTransparentImage = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => [];
  @override
  Future<Socket> detachSocket() => throw UnimplementedError();
  @override
  List<Cookie> get cookies => [];
  @override
  bool get persistentConnection => false;
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnimplementedError();
}

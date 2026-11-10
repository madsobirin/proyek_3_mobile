import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/config.dart';

class CaptchaDialog extends StatefulWidget {
  final String? siteKey;
  final String? baseUrl;

  const CaptchaDialog({
    super.key,
    this.siteKey,
    this.baseUrl,
  });

  static Future<String?> show(
    BuildContext context, {
    String? siteKey,
    String? baseUrl,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CaptchaDialog(
        siteKey: siteKey,
        baseUrl: baseUrl,
      ),
    );
  }

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isMobilePlatform {
    try {
      return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isMobilePlatform) {
      _initWebViewController();
    } else {
      _isLoading = false;
    }
  }

  void _initWebViewController() {
    final siteKey = widget.siteKey ?? Config.recaptchaSiteKey;
    final baseDomain = widget.baseUrl ?? Config.webUrl;

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
      background: transparent;
      overflow: hidden;
    }
  </style>
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  <script type="text/javascript">
    function onCaptchaVerify(token) {
      if (window.FlutterCaptcha) {
        FlutterCaptcha.postMessage(token);
      }
    }
    function onCaptchaExpired() {
      if (window.FlutterCaptcha) {
        FlutterCaptcha.postMessage("");
      }
    }
  </script>
</head>
<body>
  <div class="g-recaptcha" 
       data-sitekey="$siteKey" 
       data-callback="onCaptchaVerify" 
       data-expired-callback="onCaptchaExpired"></div>
</body>
</html>
''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterCaptcha',
        onMessageReceived: (JavaScriptMessage message) {
          final token = message.message.trim();
          if (token.isNotEmpty && mounted) {
            Navigator.of(context).pop(token);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Gagal memuat reCAPTCHA. Periksa koneksi internet.';
              });
            }
          },
        ),
      );

    controller.loadHtmlString(htmlContent, baseUrl: baseDomain);
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 340,
        height: 520,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20603D).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 20,
                        color: Color(0xFF20603D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verifikasi Keamanan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF6B7280),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Centang kotak "I\'m not a robot" untuk melanjutkan.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: !_isMobilePlatform
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.devices_rounded,
                              size: 48,
                              color: Color(0xFF20603D),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Desktop Preview Mode',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'WebView reCAPTCHA hanya berjalan di Android & iOS (Emulator / HP Fisik).',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop('dev-preview-bypass-token'),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Simulasi Lolos Captcha'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF20603D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        if (_controller != null)
                          WebViewWidget(controller: _controller!),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF20603D),
                            ),
                          ),
                        if (_errorMessage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 44,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isLoading = true;
                                        _errorMessage = null;
                                      });
                                      _initWebViewController();
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Coba Lagi'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF20603D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

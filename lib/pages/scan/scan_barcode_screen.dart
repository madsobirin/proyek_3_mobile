import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitlife/services/scan_service.dart';
import 'package:fitlife/pages/scan/widgets/scan_result_modal.dart';
import 'package:fitlife/pages/scan/scan_history_screen.dart';

class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final ScanService _scanService = ScanService();

  bool _isProcessing = false;
  bool _isLoading = false;
  bool _isTorchOn = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );

    // Request camera permission on open
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    // Cek status sekarang
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied || status.isRestricted) {
      // Minta izin ke pengguna
      status = await Permission.camera.request();
    }

    if (!mounted) return;
    setState(() => _cameraPermissionStatus = status);

    // Jika sudah granted, start kamera
    if (status.isGranted) {
      try {
        await _cameraController.start();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _lookupBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _scanService.lookupBarcode(barcode);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Tampilkan bottom sheet hasil scan
      await ScanResultModal.show(
        context,
        result,
        onDismissed: () {
          if (mounted) {
            // Beri sedikit jeda sebelum mengizinkan scan berikutnya
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) setState(() => _isProcessing = false);
            });
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(
        title: 'Informasi Produk',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Lanjutkan scan setelah menutup dialog error
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _isProcessing = false);
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: const Color(0xFF00FF66),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Pindai Lagi',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.76;

    // Tampilkan UI izin jika belum/tidak diizinkan
    if (!_cameraPermissionStatus.isGranted) {
      return _buildPermissionScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) async {
              final barcodes = capture.barcodes;
              final barcode = barcodes.firstOrNull?.rawValue;

              if (barcode == null || _isProcessing || _isLoading) return;

              setState(() => _isProcessing = true);
              await _lookupBarcode(barcode);
            },
          ),

          // Dark Mask with Center Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanWindowSize,
                    height: scanWindowSize,
                    decoration: BoxDecoration(
                      color: Colors.white, // Mask hole
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Target Viewfinder Frame & Animated Laser
          Center(
            child: SizedBox(
              width: scanWindowSize,
              height: scanWindowSize,
              child: Stack(
                children: [
                  // Corner Borders
                  CustomPaint(
                    size: Size(scanWindowSize, scanWindowSize),
                    painter: _ScannerBorderPainter(
                      color: const Color(0xFF00FF66),
                    ),
                  ),

                  // Animated Scanning Laser Line
                  if (!_isLoading && !_isProcessing)
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: scanWindowSize * _laserAnimation.value,
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF00FF66),
                                  Colors.white,
                                  Color(0xFF00FF66),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FF66).withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Loading Indicator inside scanner
                  if (_isLoading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF00FF66),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Mengambil info nutrisi...',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Instructions Text
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.18,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: Color(0xFF00FF66), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Arahkan kamera ke barcode kemasan',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top App Bar Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  _buildCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),

                  // Title Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'Pindai Makanan',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // History Button
                  _buildCircleButton(
                    icon: Icons.history_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls (Torch & Camera Switch)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Torch Button
                _buildActionButton(
                  icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  isActive: _isTorchOn,
                  label: 'Lampu',
                  onTap: () async {
                    await _cameraController.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                const SizedBox(width: 36),
                // Camera Flip Button
                _buildActionButton(
                  icon: Icons.flip_camera_ios_rounded,
                  isActive: false,
                  label: 'Putar',
                  onTap: () => _cameraController.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00FF66) : Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? const Color(0xFF00FF66) : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF111827) : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen() {
    final isPermanentlyDenied = _cameraPermissionStatus.isPermanentlyDenied;
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF66).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFF00FF66).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 48,
                  color: Color(0xFF00FF66),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Izin Kamera Diperlukan',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isPermanentlyDenied
                    ? 'Akses kamera ditolak secara permanen. Buka Pengaturan → Aplikasi → Fitlife → Izin, lalu aktifkan Kamera.'
                    : 'Aplikasi memerlukan akses kamera untuk memindai barcode makanan. Silakan izinkan akses kamera.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isPermanentlyDenied
                      ? () async {
                          await openAppSettings();
                        }
                      : _checkCameraPermission,
                  icon: Icon(
                    isPermanentlyDenied
                        ? Icons.settings_rounded
                        : Icons.camera_alt_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isPermanentlyDenied ? 'Buka Pengaturan' : 'Izinkan Kamera',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    foregroundColor: const Color(0xFF111827),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Kembali',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerBorderPainter extends CustomPainter {
  final Color color;

  _ScannerBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 32.0;
    const radius = 24.0;

    // Top-Left
    final topLeft = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(topLeft, paint);

    // Top-Right
    final topRight = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(topRight, paint);

    // Bottom-Left
    final bottomLeft = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - radius)
      ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(bottomLeft, paint);

    // Bottom-Right
    final bottomRight = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

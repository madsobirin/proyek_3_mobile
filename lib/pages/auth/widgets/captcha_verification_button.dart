import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CaptchaVerificationButton extends StatelessWidget {
  final bool isVerified;
  final bool isLoading;
  final VoidCallback onTap;

  const CaptchaVerificationButton({
    super.key,
    required this.isVerified,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isVerified
              ? const Color(0xFFDCFCE7).withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF15803D)
                : const Color(0xFFE5E7EB),
            width: isVerified ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isVerified
                    ? const Color(0xFF15803D)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isVerified
                      ? const Color(0xFF15803D)
                      : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isVerified
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isVerified
                    ? 'reCAPTCHA Terverifikasi'
                    : 'Verifikasi Saya Bukan Robot',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isVerified ? FontWeight.w600 : FontWeight.w500,
                  color: isVerified
                      ? const Color(0xFF15803D)
                      : const Color(0xFF374151),
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF20603D),
                ),
              )
            else
              Image.network(
                'https://www.gstatic.com/recaptcha/api2/logo_48.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.security_rounded,
                  size: 24,
                  color: Color(0xFF9CA3AF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

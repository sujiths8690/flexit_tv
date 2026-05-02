// lib/widgets/qr_code_widget.dart
//
// Renders a styled QR code.
// Uses the `qr_flutter` package — add to pubspec.yaml:
//   qr_flutter: ^4.1.0
//
// The QR encodes the JSON payload that your mobile app reads.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const QrCodeWidget({
    super.key,
    required this.data,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 40,
      height: size + 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C28), Color(0xFF13131A)],
        ),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.15),
            blurRadius: 50,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0A0A0F),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0A0A0F),
                ),
                // Center logo
                embeddedImage: null, // Replace with AssetImage('assets/logo.png')
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(40, 40),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'SCAN TO CONNECT',
                style: TextStyle(
                  fontFamily: GoogleFonts.nunito().fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

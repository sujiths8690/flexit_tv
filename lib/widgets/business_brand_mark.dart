import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class BusinessBrandMark extends StatelessWidget {
  final String? businessName;
  final String? logoUrl;
  final bool darkBackdrop;

  const BusinessBrandMark({
    super.key,
    required this.businessName,
    this.logoUrl,
    this.darkBackdrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = businessName?.trim();
    final logo = logoUrl?.trim();

    if ((name == null || name.isEmpty) && (logo == null || logo.isEmpty)) {
      return const SizedBox.shrink();
    }

    final foreground = darkBackdrop
        ? Colors.white.withValues(alpha: 0.58)
        : const Color(0xFF221A10).withValues(alpha: 0.46);

    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.bottomRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logo != null && logo.isNotEmpty) ...[
                    _LogoImage(url: _absoluteUrl(logo)),
                    if (name != null && name.isNotEmpty)
                      const SizedBox(width: 6),
                  ],
                  if (name != null && name.isNotEmpty)
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _absoluteUrl(String url) {
    if (url.startsWith('http')) return url;
    final path = url.startsWith('/') ? url.substring(1) : url;
    return 'http://192.168.29.184:3002/$path';
  }
}

class _LogoImage extends StatelessWidget {
  final String url;

  const _LogoImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.network(
        url,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.storefront_outlined,
          color: AppTheme.whiteDim,
          size: 16,
        ),
      ),
    );
  }
}

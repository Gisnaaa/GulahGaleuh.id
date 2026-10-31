import 'package:flutter/material.dart';

/// Palet biru pastel. `primary` adalah biru navy lembut yang dipakai
/// untuk teks & ikon agar tetap terbaca di atas latar pastel.
class AppColors {
  static const bg = Color(0xFFEEF6FD); // latar langit pucat
  static const card = Color(0xFFFFFFFF); // permukaan kartu
  static const primary = Color(0xFF1F3B5C); // navy (teks, ikon)
  static const secondary = Color(0xFF5E7A99); // teks sekunder
  static const blue = Color(0xFF9CCBF2); // biru pastel utama (tombol, aksen)
  static const accent = Color(0xFFB9DAF7); // biru pastel sedang
  static const accentLight = Color(0xFFD9ECFB); // panel gambar
  static const chip = Color(0xFFE1EFFB);
  static const border = Color(0xFFCFE4F6);
  static const star = Color(0xFFF0B45F);
}

class AppStyle {
  /// Panel datar dengan garis tepi tipis (pengganti bayangan neumorphic).
  static BoxDecoration panel({
    double radius = 20,
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.border, width: 1.5),
    );
  }

  static InputDecoration input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.secondary),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.bg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 2.2),
      ),
    );
  }
}

/// Tombol ikon persegi membulat (back, tambah, keranjang, dll).
class SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  const SoftIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: AppStyle.panel(radius: size * 0.34),
          child: Icon(icon, color: AppColors.primary, size: size * 0.46),
        ),
      ),
    );
  }
}

/// Tombol utama: biru pastel, teks navy, datar.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14.5)),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
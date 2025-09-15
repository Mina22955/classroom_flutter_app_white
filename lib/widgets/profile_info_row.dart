import 'package:flutter/material.dart';

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final IconData? icon;

  const ProfileInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: const Color(0xFF0A84FF),
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

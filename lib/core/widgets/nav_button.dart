import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';

class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget destination;
  final bool isInverted;

  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.destination,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isInverted ? AppTheme.surfaceWhite : AppTheme.primaryDark;
    final Color fgColor = isInverted ? AppTheme.primaryDark : AppTheme.surfaceWhite;
    final BorderSide border = isInverted 
        ? const BorderSide(color: AppTheme.primaryDark, width: 2) 
        : BorderSide.none;

    return SizedBox(
      width: double.infinity, // Wymuszenie równej szerokości w kontenerze
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        icon: Icon(icon, size: 28, color: fgColor),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          side: border,
          padding: const EdgeInsets.symmetric(vertical: 16), // Usunięto poziomy padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isInverted ? 0 : 2,
        ),
      ),
    );
  }
}
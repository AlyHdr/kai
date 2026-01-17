import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onGoogle,
    this.onApple,
    this.busy = false,
  });

  final VoidCallback onGoogle;
  final VoidCallback? onApple;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SocialButton(
          onPressed: busy ? null : onGoogle,
          color: Colors.white,
          borderColor: Colors.black12,
          textColor: Colors.black87,
          icon: const FaIcon(FontAwesomeIcons.google, color: Color(0xFF4285F4)),
          label: 'Continue with Google',
        ),
        const SizedBox(height: 12),
        if (isIOS && onApple != null)
          _SocialButton(
            onPressed: busy ? null : onApple,
            color: Colors.black,
            borderColor: Colors.black,
            textColor: Colors.white,
            icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white),
            label: 'Continue with Apple',
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.textColor,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(label, style: TextStyle(color: textColor)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: color,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

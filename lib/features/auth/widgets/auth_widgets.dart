import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';

// ── Themed text field ─────────────────────────────────────────────────────────
class ThemedField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Color surfaceColor, borderColor, textColor, hintColor;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  const ThemedField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.textInputAction,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.hintColor,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
  });

  @override
  State<ThemedField> createState() => _ThemedFieldState();
}

class _ThemedFieldState extends State<ThemedField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(
        () => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted ??
          (_) {
            if (widget.nextFocus != null) {
              FocusScope.of(context).requestFocus(widget.nextFocus);
            }
          },
      validator: widget.validator,
      style: AppFonts.input.copyWith(color: widget.textColor),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppFonts.inputHint.copyWith(color: widget.hintColor),
        prefixIcon: Icon(
          widget.prefixIcon,
          size: 18,
          color: _focused ? AppColors.teal : widget.hintColor,
        ),
        suffixIcon: widget.suffixIcon,
        filled: true,
        fillColor: widget.surfaceColor,
        contentPadding: AppStyles.paddingField,
        border: OutlineInputBorder(
          borderRadius: AppStyles.radiusMd,
          borderSide: BorderSide(color: widget.borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusMd,
          borderSide: BorderSide(color: widget.borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusMd,
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(
            fontSize: 11, color: AppColors.error, height: 1.4),
      ),
    );
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: AppStyles.gradientButton(dimmed: isLoading),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: AppStyles.radiusMd),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(label, style: AppFonts.button),
        ),
      ),
    );
  }
}
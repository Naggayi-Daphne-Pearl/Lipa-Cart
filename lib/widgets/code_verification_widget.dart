import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';

/// Widget for rider to enter 4-digit delivery code
class CodeVerificationWidget extends StatefulWidget {
  final Function(String code) onCodeSubmit;
  final int attemptsRemaining;
  final bool isLocked;
  final String? errorMessage;
  final bool isLoading;

  const CodeVerificationWidget({
    super.key,
    required this.onCodeSubmit,
    this.attemptsRemaining = 3,
    this.isLocked = false,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  State<CodeVerificationWidget> createState() => _CodeVerificationWidgetState();
}

class _CodeVerificationWidgetState extends State<CodeVerificationWidget> {
  late List<TextEditingController> _codeControllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _codeControllers =
        List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleDigitInput(int index, String value) {
    if (value.isEmpty) return;

    if (!RegExp(r'^\d$').hasMatch(value)) return;

    _codeControllers[index].text = value;

    // Auto-move to next field
    if (index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last field - trigger submission
      _focusNodes[index].unfocus();
      _submitCode();
    }
  }

  void _handleBackspace(int index, RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.backspace) &&
        _codeControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _codeControllers[index - 1].clear();
    }
  }

  String _buildFullCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  void _submitCode() {
    final fullCode = _buildFullCode();
    if (fullCode.length == 4) {
      widget.onCodeSubmit(fullCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'Enter Delivery Code',
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 8),
        Text(
          'Customer, please read your 4-digit code',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 24),

        // Code input fields
        if (!widget.isLocked)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => _CodeInputField(
                controller: _codeControllers[index],
                focusNode: _focusNodes[index],
                onChanged: (value) => _handleDigitInput(index, value),
                onKey: (event) => _handleBackspace(index, event),
                isLoading: widget.isLoading,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.lock_1,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Maximum attempts exceeded.\nPlease contact support.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h5.copyWith(
                    color: AppColors.error,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Error or status message
        if (widget.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.close_circle,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (!widget.isLocked)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.sm,
            ),
            child: Text(
              'Attempts remaining: ${widget.attemptsRemaining}',
              style: AppTextStyles.bodySmall.copyWith(
                color: widget.attemptsRemaining == 1
                    ? AppColors.error
                    : AppColors.grey600,
                fontWeight: widget.attemptsRemaining == 1
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.isLoading || widget.isLocked
                ? null
                : _submitCode,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.white,
                      ),
                    ),
                  )
                : const Text('Verify Code'),
          ),
        ),
      ],
    );
  }
}

/// Individual code input field
class _CodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function(RawKeyEvent) onKey;
  final bool isLoading;

  const _CodeInputField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: onKey,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: !isLoading,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: AppColors.grey50,
          ),
          style: AppTextStyles.displaySm.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

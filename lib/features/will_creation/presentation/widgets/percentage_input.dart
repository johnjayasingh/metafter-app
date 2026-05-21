import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// A reusable percentage input widget with manual text entry
/// and increment/decrement buttons.
///
/// Accepts decimal values like "10.5" as well as fraction strings like "1/2".
/// Pass [displayText] to control exactly what is shown in the field when not focused
/// (e.g. "1/2", "50.0", "10.5"). If null the numeric [value] is formatted.
class PercentageInput extends StatefulWidget {
  final double value;
  final void Function(double value, {String? rawString}) onChanged;
  final double min;
  final double max;
  final double step;
  /// When non-null, this string is displayed in the field when it is not focused.
  /// Supports fractions ("1/2"), decimals ("10.5"), or any raw string from the API.
  final String? displayText;

  const PercentageInput({
    Key? key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.step = 1.0,
    this.displayText,
  }) : super(key: key);

  @override
  State<PercentageInput> createState() => _PercentageInputState();
}

class _PercentageInputState extends State<PercentageInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.displayText ?? _formatValue(widget.value),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      // On blur, commit the value then restore the display string
      _handleTextChange(_controller.text);
      _controller.text = widget.displayText ?? _formatValue(widget.value);
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(PercentageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      if (oldWidget.value != widget.value ||
          oldWidget.displayText != widget.displayText) {
        _controller.text = widget.displayText ?? _formatValue(widget.value);
      }
    }
  }

  String _formatValue(double value) {
    if (value == 0) return '0';
    String formatted = value.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    if (formatted.endsWith('0') && formatted.contains('.')) {
      return formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  /// Parses a string that can be either a decimal ("10.5") or a fraction ("1/2").
  /// Returns null if the string cannot be parsed.
  double? _parseInput(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0.0;

    // Try plain decimal / integer first
    final direct = double.tryParse(trimmed);
    if (direct != null) return direct;

    // Try fraction notation "a/b"
    final parts = trimmed.split('/');
    if (parts.length == 2) {
      final numerator = double.tryParse(parts[0].trim());
      final denominator = double.tryParse(parts[1].trim());
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator * 100.0;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    _focusNode.unfocus();
    if (widget.value < widget.max) {
      final newValue = (widget.value + widget.step).clamp(widget.min, widget.max);
      widget.onChanged(newValue);
      _controller.text = _formatValue(newValue);
    }
  }

  void _decrement() {
    _focusNode.unfocus();
    if (widget.value > widget.min) {
      final newValue = (widget.value - widget.step).clamp(widget.min, widget.max);
      widget.onChanged(newValue);
      _controller.text = _formatValue(newValue);
    }
  }

  void _handleTextChange(String text) {
    if (text.isEmpty) {
      widget.onChanged(0.0, rawString: '0');
      return;
    }

    final parsed = _parseInput(text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      // Pass the raw text so callers can preserve fractions like "1/2"
      widget.onChanged(clamped, rawString: text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppColors.textPrimary
              : AppColors.borderInputContainer,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 24,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.visiblePassword,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d./]')),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                isDense: true,
              ),
              onChanged: _handleTextChange,
              onSubmitted: (value) {
                _handleTextChange(value);
                _focusNode.unfocus();
                _controller.text = widget.displayText ?? _formatValue(widget.value);
              },
            ),
          ),
          const Text(
            '%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          // Up/Down arrows
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _increment,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Icon(Icons.keyboard_arrow_up, size: 20, color: AppColors.textPrimary),
                ),
              ),
              GestureDetector(
                onTap: _decrement,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

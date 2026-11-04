import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';

/// Rounded-square red-tinted glyph badge that heads the auth screens.
class AuthIconBadge extends StatelessWidget {
  const AuthIconBadge({super.key, required this.icon, this.size, this.iconSize});

  final IconData icon;
  final double? size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 60.w;
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, color: AppColors.redSolid, size: iconSize ?? 28.sp),
    );
  }
}

/// Three-segment progress rail shown above the sign-up steps.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, this.steps = 3});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps, (i) {
        return Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.only(right: i == steps - 1 ? 0 : 12.w),
            decoration: BoxDecoration(
              color: i <= step ? AppColors.redSolid : const Color(0xFF4A4A4E),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        );
      }),
    );
  }
}

/// Six boxed digits used by both OTP screens.
///
/// The boxes are decoration; a single hidden [TextField] behind them owns the
/// text. That is deliberate — the earlier version rebuilt a throwaway
/// `TextEditingController` on every frame, which reset the selection and made
/// backspace and mid-code editing behave unpredictably. One long-lived
/// controller gets deletion, editing, paste and SMS autofill for free.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 6,
    this.autofocus = false,
    this.onCompleted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int length;
  final bool autofocus;

  /// Fired once the last digit lands, for auto-submitting the code.
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  /// Set while this widget is writing to the controller itself, so the
  /// listener does not re-enter — and, crucially, does not call `setState`
  /// from inside `didUpdateWidget`, which runs during a build.
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value)
      ..selection = TextSelection.collapsed(offset: widget.value.length);
    _focusNode = FocusNode();
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only follow the owner when it actually diverges — e.g. the code was
    // cleared on resend — otherwise this would fight the user's typing.
    if (widget.value != _controller.text) {
      _syncing = true;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onControllerChanged() {
    if (_syncing) return;
    final text = _controller.text;
    // The caret always sits after the last digit, so backspace deletes the
    // digit the user can see is last, wherever they happened to tap.
    if (!_controller.selection.isCollapsed || _controller.selection.baseOffset != text.length) {
      _syncing = true;
      _controller.selection = TextSelection.collapsed(offset: text.length);
      _syncing = false;
    }
    setState(() {});
    if (text != widget.value) {
      widget.onChanged(text);
      if (text.length == widget.length) widget.onCompleted?.call(text);
    }
  }

  void _requestEdit() {
    _focusNode.requestFocus();
    _syncing = true;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text;
    final focused = _focusNode.hasFocus;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _requestEdit,
      child: Stack(
        alignment: Alignment.center,
        children: [
          OtpBoxes(value: value, length: widget.length, active: focused),
          // Zero-size so it can never steal a tap or paint over the boxes; it
          // is the focus target, not the visible field.
          SizedBox(
            width: 0,
            height: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              enableInteractiveSelection: false,
              showCursor: false,
              cursorWidth: 0,
              style: const TextStyle(color: Colors.transparent, height: 0.01),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The boxes themselves. Presentation only — [OtpInput] drives them.
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({super.key, required this.value, this.length = 6, this.active = true});

  final String value;
  final int length;

  /// Whether the caret box is highlighted, i.e. the field has focus.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (i) {
        final filled = i < value.length;
        final caret = active && i == value.length;
        return Container(
          width: 52.w,
          height: 55.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: caret ? AppColors.redSolid : AppColors.border,
              width: caret ? 1.5 : 1,
            ),
          ),
          child: filled
              ? Text(
                  value[i],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 19.2.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                )
              : caret
              ? Container(width: 2.w, height: 26.h, color: AppColors.redSolid)
              : null,
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';

class SimpleButton extends StatelessWidget {

  const SimpleButton(
      {this.child,
        this.color,
        this.onPressed,
        this.disabled = false,
        this.borderRadius = 6,
        this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        Key? key})
      : super(key: key);

  final bool disabled;
  final Color? color;
  final Widget? child;
  final Function? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    ThemeData currentTheme = Theme.of(context);
    return ElevatedButton(
      child: child,
      style: ElevatedButton.styleFrom(
        enableFeedback: !disabled,
        padding: padding,
        primary: color ?? currentTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onPressed as void Function()?,
    );
  }
}
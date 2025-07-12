import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'custom_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final String? lottieAsset;
  final String? imagePath;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double? imageWidth;
  final double? imageHeight;

  const EmptyState({
    Key? key,
    required this.title,
    this.message,
    this.lottieAsset,
    this.imagePath,
    this.buttonText,
    this.onButtonPressed,
    this.imageWidth = 200,
    this.imageHeight = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (lottieAsset != null)
            Lottie.asset(
              lottieAsset!,
              width: imageWidth,
              height: imageHeight,
            )
          else if (imagePath != null)
            Image.asset(
              imagePath!,
              width: imageWidth,
              height: imageHeight,
            ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: buttonText!,
              onPressed: onButtonPressed!,
              isFullWidth: false,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }
}
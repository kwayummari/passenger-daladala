import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'custom_button.dart';

class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String? lottieAsset;
  final String? buttonText;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.title = 'Oops!',
    required this.message,
    this.lottieAsset,
    this.buttonText = 'Try Again',
    this.onRetry,
  });

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
              width: 200,
              height: 200,
            )
          else
            Icon(
              Icons.error_outline_rounded,
              size: 70,
              color: theme.colorScheme.error,
            ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: buttonText!,
              onPressed: onRetry!,
              isFullWidth: false,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }
}

class NetworkErrorView extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorView({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      lottieAsset: 'assets/animations/no_internet.json',
      onRetry: onRetry,
    );
  }
}

class ServerErrorView extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorView({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      lottieAsset: 'assets/animations/server_error.json',
      onRetry: onRetry,
    );
  }
}

class GenericErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const GenericErrorView({
    Key? key,
    this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      title: 'Something Went Wrong',
      message: message ?? 'An unexpected error occurred. Please try again.',
      lottieAsset: 'assets/animations/error.json',
      onRetry: onRetry,
    );
  }
}
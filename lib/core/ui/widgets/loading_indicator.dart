import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';

enum LoadingIndicatorType { spinner, circular, lottie }

class LoadingIndicator extends StatelessWidget {
  final LoadingIndicatorType type;
  final double size;
  final Color? color;
  final String? lottieAsset;
  final String? message;

  const LoadingIndicator({
    Key? key,
    this.type = LoadingIndicatorType.spinner,
    this.size = 40.0,
    this.color,
    this.lottieAsset,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.primaryColor;

    Widget indicator;
    switch (type) {
      case LoadingIndicatorType.spinner:
        indicator = SpinKitFadingCircle(
          color: indicatorColor,
          size: size,
        );
        break;
      case LoadingIndicatorType.circular:
        indicator = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            strokeWidth: 3,
          ),
        );
        break;
      case LoadingIndicatorType.lottie:
        indicator = Lottie.asset(
          lottieAsset ?? 'assets/animations/loading.json',
          width: size,
          height: size,
        );
        break;
    }

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;
  final LoadingIndicatorType type;

  const FullScreenLoading({
    Key? key,
    this.message,
    this.type = LoadingIndicatorType.spinner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: LoadingIndicator(
            type: type,
            message: message,
          ),
        ),
      ),
    );
  }
}
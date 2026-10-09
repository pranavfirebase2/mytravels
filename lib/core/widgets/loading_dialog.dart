import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LoadingDialog {
  static void show(BuildContext context, {String? message, ValueNotifier<String>? messageNotifier}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return PopScope(
          canPop: false, // Prevent back button from closing it
          child: Dialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryBlue),
                  const SizedBox(height: 24),
                  if (messageNotifier != null)
                    ValueListenableBuilder<String>(
                      valueListenable: messageNotifier,
                      builder: (context, value, _) {
                        return Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    )
                  else if (message != null)
                    Text(
                      message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please do not press back or close the app.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

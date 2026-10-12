import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'url_helper_stub.dart'
    if (dart.library.js_interop) 'url_helper_web.dart';

Future<void> openExternalUrl(String url) async {
  if (kIsWeb) {
    try {
      launchUrlWeb(url);
      return;
    } catch (_) {
      // Fallback below
    }
  }

  final uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri);
    }
  } catch (_) {
    if (kIsWeb) {
      launchUrlWeb(url);
    } else {
      rethrow;
    }
  }
}

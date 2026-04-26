import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_update_service.dart';
import 'theme_provider.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppUpdateService(prefs);
});

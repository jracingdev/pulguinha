import 'package:package_info_plus/package_info_plus.dart';

/// Versão lida do `pubspec.yaml` em tempo de execução (fonte única no build).
class AppVersionService {
  AppVersionService._();

  static PackageInfo? _info;

  static Future<void> initialize() async {
    _info = await PackageInfo.fromPlatform();
  }

  static String get version => _info?.version ?? '0.0.0';

  static String get buildNumber => _info?.buildNumber ?? '0';

  /// Ex.: v1.1.0 (2)
  static String get label => 'v$version ($buildNumber)';

  /// Ex.: pulguinha-1.1.0-build2
  static String get apkFileName => 'pulguinha-$version-build$buildNumber.apk';
}

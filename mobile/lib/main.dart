import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/pos_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1. Check for updates
    try {
      final posService = PosService();
      final versionInfo = await posService.checkAppVersion();
      
      if (versionInfo != null && versionInfo['latest_version'] != null) {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        final latestVersion = versionInfo['latest_version'];
        final isMandatory = versionInfo['is_mandatory_update'] ?? false;
        final apkUrl = versionInfo['apk_url'];

        if (_isVersionLower(currentVersion, latestVersion)) {
          if (mounted) {
            final shouldBlock = await _showUpdateDialog(latestVersion, isMandatory, apkUrl);
            if (shouldBlock) return; // Stop app initialization if mandatory
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }

    // 2. Original Auth logic
    await _authService.checkPersistentSession();
    final token = await _authService.getToken();
    if (mounted) {
      setState(() {
        if (token != null) {
          _home = const DashboardScreen();
        } else {
          _home = const LoginScreen();
        }
      });
    }
  }

  bool _isVersionLower(String current, String latest) {
    try {
      List<int> c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (int i = 0; i < 3; i++) {
        int cv = i < c.length ? c[i] : 0;
        int lv = i < l.length ? l[i] : 0;
        if (lv > cv) return true;
        if (lv < cv) return false;
      }
    } catch (e) {
      debugPrint('Version comparison error: $e');
    }
    return false;
  }

  Future<bool> _showUpdateDialog(String latestVersion, bool isMandatory, String? apkUrl) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A new version ($latestVersion) is available.'),
            const SizedBox(height: 10),
            Text(isMandatory 
              ? 'This is a mandatory update. Please update to continue using the app.' 
              : 'Would you like to update now?'),
          ],
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (apkUrl != null && apkUrl.isNotEmpty) {
                final url = Uri.parse(apkUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    ) ?? isMandatory;
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'K-Beauty House',
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      home: _home,
    );
  }
}

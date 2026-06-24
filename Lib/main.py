import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dashboard.dart';
import 'trade_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TradingProvider()),
      ],
      child: const SaadBotApp(),
    ),
  );
}

class SaadBotApp extends StatelessWidget {
  const SaadBotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saad Trading Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C087),
          secondary: Color(0xFF00C087),
          surface: Color(0xFF141B2D),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0E1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C087),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiKeyController    = TextEditingController();
  final _apiSecretController = TextEditingController();
  bool _obscureSecret = true;
  bool _isLoading     = false;
  String _statusMsg   = '';

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final key    = _apiKeyController.text.trim();
    final secret = _apiSecretController.text.trim();

    if (key.isEmpty || secret.isEmpty) {
      _showMsg('Please enter both API key and secret', isError: true);
      return;
    }
    if (key.length < 10 || secret.length < 10) {
      _showMsg('API key/secret looks too short. Check and retry.', isError: true);
      return;
    }

    setState(() {
      _isLoading  = true;
      _statusMsg  = 'Connecting to Bybit Demo...';
    });

    try {
      final provider = Provider.of<TradingProvider>(context, listen: false);
      await provider.initialize(key, secret);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception:', '').trim(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    setState(() => _statusMsg = msg);
    if (isError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF1E2A3A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF141B2D),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00C087), width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C087), Color(0xFF0066FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C087).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.candlestick_chart_rounded,
                          size: 46, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Saad Bot',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Auto Trading with ATR Trailing Stop',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text('Bybit Demo API Key',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[300])),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration('Paste your API key here'),
              ),
              const SizedBox(height: 18),
              Text('Bybit Demo API Secret',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[300])),
              const SizedBox(height: 8),
              TextField(
                controller: _apiSecretController,
                obscureText: _obscureSecret,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration(
                  'Paste your API secret here',
                  suffix: IconButton(
                    icon: Icon(
                      _obscureSecret ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureSecret = !_obscureSecret),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get Demo keys: bybit.com → Account → API Management',
                style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF00C087).withOpacity(0.8)),
              ),
              const SizedBox(height: 32),
              if (_statusMsg.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141B2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00C087).withOpacity(0.3)),
                  ),
                  child: Text(_statusMsg,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center),
                ),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C087),
                    disabledBackgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: const Color(0xFF00C087).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                  strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(_statusMsg.isEmpty
                                ? 'Connecting...'
                                : _statusMsg,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ],
                        )
                      : const Text(
                          'CONNECT & START TRADING',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141B2D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00C087).withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.verified_user,
                          color: Color(0xFF00C087), size: 16),
                      const SizedBox(width: 8),
                      const Text('Security & Safety',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C087))),
                    ]),
                    const SizedBox(height: 10),
                    ...[
                      'Demo mode only — zero real money risk',
                      'API keys stored securely on your device',
                      'Keys never sent to any third party',
                      'Trades BTC, SOL, LINK, XRP automatically',
                    ].map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF00C087), size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(t,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

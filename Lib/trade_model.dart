import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

// ================================================================
// DATA MODELS
// ================================================================
class Trade {
  final String  symbol;
  final String  direction;
  final double  price;
  final double  quantity;
  final double? stopLoss;
  final String  timestamp;
  final String  status;

  Trade({
    required this.symbol,
    required this.direction,
    required this.price,
    required this.quantity,
    this.stopLoss,
    required this.timestamp,
    this.status = 'Filled',
  });
}

class Position {
  final String symbol;
  final String side;
  final double contracts;
  final double entryPrice;
  final double unrealizedPnl;
  final double stopLoss;
  final double takeProfit;

  Position({
    required this.symbol,
    required this.side,
    required this.contracts,
    required this.entryPrice,
    required this.unrealizedPnl,
    this.stopLoss   = 0,
    this.takeProfit = 0,
  });
}

// ================================================================
// TRADING PROVIDER
// ================================================================
class TradingProvider extends ChangeNotifier {
  ApiService? _api;

  bool   _isRunning    = false;
  double _balance      = 0;
  double _totalPnL     = 0;
  String _lastUpdate   = '--:--:--';
  String _statusMsg    = 'Not connected';

  Map<String, Position> _positions = {};
  List<Trade>           _trades    = [];
  Timer?                _timer;

  // ── Getters ──
  bool                  get isRunning   => _isRunning;
  double                get balance     => _balance;
  double                get totalPnL    => _totalPnL;
  String                get lastUpdate  => _lastUpdate;
  String                get statusMsg   => _statusMsg;
  Map<String, Position> get positions   => _positions;
  List<Trade>           get trades      => _trades;
  bool                  get isConnected => _api != null;

  // ================================================================
  // INITIALIZE (called from login)
  // ================================================================
  Future<void> initialize(String apiKey, String apiSecret) async {
    _api = ApiService(apiKey: apiKey, apiSecret: apiSecret);
    _statusMsg = 'Testing connection...';
    notifyListeners();

    await _api!.testConnection(); // throws on error

    _statusMsg = 'Connected!';
    notifyListeners();

    await _refresh();
  }

  // ================================================================
  // BOT CONTROLS
  // ================================================================
  void startBot() {
    if (_isRunning) return;
    _isRunning = true;
    _statusMsg = 'Bot is RUNNING';
    notifyListeners();
    _startPolling();
  }

  void stopBot() {
    _isRunning = false;
    _statusMsg = 'Bot STOPPED';
    _timer?.cancel();
    notifyListeners();
  }

  void startPolling()  => _startPolling();
  void cancelPolling() => _timer?.cancel();

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  // ================================================================
  // DATA REFRESH
  // ================================================================
  Future<void> _refresh() async {
    if (_api == null) return;
    try {
      final balance   = await _api!.fetchBalance();
      final positions = await _api!.fetchPositions();
      final trades    = await _api!.fetchRecentTrades();

      double pnl = 0;
      positions.forEach((_, p) => pnl += p.unrealizedPnl);

      final now = DateTime.now();
      _balance     = balance;
      _positions   = positions;
      _trades      = trades;
      _totalPnL    = pnl;
      _lastUpdate  =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
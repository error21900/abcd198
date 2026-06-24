import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'trade_model.dart';

class ApiService {
  final String apiKey;
  final String apiSecret;

  // ✅ CORRECT Bybit Demo Trading URL
  static const String _baseUrl = 'https://api-demo.bybit.com';

  ApiService({required this.apiKey, required this.apiSecret});

  // ================================================================
  // AUTHENTICATION HELPERS
  // ================================================================
  String _sign(String payload) {
    final key  = utf8.encode(apiSecret);
    final data = utf8.encode(payload);
    return Hmac(sha256, key).convert(data).toString();
  }

  Map<String, String> _headers({String body = '', String queryString = ''}) {
    final ts         = DateTime.now().millisecondsSinceEpoch.toString();
    const recvWindow = '20000';
    final raw        = '$ts$apiKey$recvWindow${body.isNotEmpty ? body : queryString}';
    final signature  = _sign(raw);

    return {
      'X-BAPI-API-KEY':      apiKey,
      'X-BAPI-TIMESTAMP':    ts,
      'X-BAPI-RECV-WINDOW':  recvWindow,
      'X-BAPI-SIGN':         signature,
      'Content-Type':        'application/json',
    };
  }

  // ================================================================
  // PUBLIC METHODS
  // ================================================================

  /// Test connection & verify API keys are valid
  Future<void> testConnection() async {
    try {
      final qs  = 'accountType=UNIFIED';
      final uri = Uri.parse('$_baseUrl/v5/account/wallet-balance?$qs');
      final res = await http
          .get(uri, headers: _headers(queryString: qs))
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      final code = body['retCode'];

      if (code == 0) return; // ✅ Success

      // Map common error codes to helpful messages
      final msg = body['retMsg'] ?? 'Unknown error';
      if (code == 10003 || code == 10004) {
        throw Exception('Invalid API key or secret. Check and try again.');
      } else if (code == 10005) {
        throw Exception('API key has insufficient permissions. Enable Futures trading.');
      } else {
        throw Exception('Bybit error ($code): $msg');
      }
    } on SocketException {
      throw Exception(
          'No internet connection. Make sure your phone has WiFi or mobile data.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response from Bybit server.');
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Connection failed: $e');
    }
  }

  /// Fetch USDT wallet balance
  Future<double> fetchBalance() async {
    try {
      const qs  = 'accountType=UNIFIED';
      final uri = Uri.parse('$_baseUrl/v5/account/wallet-balance?$qs');
      final res = await http
          .get(uri, headers: _headers(queryString: qs))
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['retCode'] != 0) return 0;

      final list = body['result']?['list'] as List? ?? [];
      for (final account in list) {
        final coins = account['coin'] as List? ?? [];
        for (final coin in coins) {
          if (coin['coin'] == 'USDT') {
            return double.tryParse(coin['walletBalance'].toString()) ?? 0;
          }
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Fetch open positions
  Future<Map<String, Position>> fetchPositions() async {
    final result = <String, Position>{};
    try {
      const qs  = 'category=linear&settleCoin=USDT';
      final uri = Uri.parse('$_baseUrl/v5/position/list?$qs');
      final res = await http
          .get(uri, headers: _headers(queryString: qs))
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['retCode'] != 0) return result;

      final list = body['result']?['list'] as List? ?? [];
      for (final pos in list) {
        final size = double.tryParse(pos['size'].toString()) ?? 0;
        if (size <= 0) continue;

        final sym = pos['symbol'].toString();
        result[sym] = Position(
          symbol:        sym,
          side:          pos['side'].toString().toLowerCase(),
          contracts:     size,
          entryPrice:    double.tryParse(pos['avgPrice'].toString()) ?? 0,
          unrealizedPnl: double.tryParse(pos['unrealisedPnl'].toString()) ?? 0,
          stopLoss:      double.tryParse(pos['stopLoss'].toString()) ?? 0,
          takeProfit:    double.tryParse(pos['takeProfit'].toString()) ?? 0,
        );
      }
    } catch (_) {}
    return result;
  }

  /// Fetch recent closed orders as trade history
  Future<List<Trade>> fetchRecentTrades() async {
    final trades = <Trade>[];
    try {
      final coins = ['BTCUSDT', 'SOLUSDT', 'LINKUSDT', 'XRPUSDT'];
      for (final coin in coins) {
        final qs  = 'category=linear&symbol=$coin&limit=5';
        final uri = Uri.parse('$_baseUrl/v5/order/history?$qs');
        final res = await http
            .get(uri, headers: _headers(queryString: qs))
            .timeout(const Duration(seconds: 10));

        final body = jsonDecode(res.body);
        if (body['retCode'] != 0) continue;

        final list = body['result']?['list'] as List? ?? [];
        for (final o in list) {
          if (o['orderStatus'] != 'Filled') continue;
          trades.add(Trade(
            symbol:    o['symbol'].toString(),
            direction: o['side'].toString() == 'Buy' ? 'LONG' : 'SHORT',
            price:     double.tryParse(o['avgPrice'].toString()) ?? 0,
            quantity:  double.tryParse(o['qty'].toString()) ?? 0,
            stopLoss:  double.tryParse(o['stopLoss'].toString()),
            timestamp: _formatTime(o['createdTime'].toString()),
            status:    o['orderStatus'].toString(),
          ));
        }
      }

      // Sort newest first
      trades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {}
    return trades;
  }

  String _formatTime(String msStr) {
    try {
      final ms = int.parse(msStr);
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${dt.hour.toString().padLeft(2, '0')}:'
             '${dt.minute.toString().padLeft(2, '0')}:'
             '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--:--';
    }
  }
}
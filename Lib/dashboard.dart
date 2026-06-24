import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trade_model.dart';

// ================================================================
// DASHBOARD SCREEN
// ================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TradingProvider>(context, listen: false).startPolling();
    });
  }

  @override
  void dispose() {
    Provider.of<TradingProvider>(context, listen: false).cancelPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C087), Color(0xFF0066FF)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.candlestick_chart_rounded,
              color: Colors.white, size: 18),
        ),
        title: const Text('Saad Bot',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        actions: [
          Consumer<TradingProvider>(builder: (_, p, __) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.isRunning
                    ? const Color(0xFF00C087).withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: p.isRunning ? const Color(0xFF00C087) : Colors.red,
                    width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color:
                          p.isRunning ? const Color(0xFF00C087) : Colors.red,
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  p.isRunning ? 'LIVE' : 'OFF',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: p.isRunning
                          ? const Color(0xFF00C087)
                          : Colors.red),
                ),
              ]),
            );
          }),
        ],
      ),
      body: Consumer<TradingProvider>(builder: (_, provider, __) {
        return RefreshIndicator(
          color: const Color(0xFF00C087),
          backgroundColor: const Color(0xFF141B2D),
          onRefresh: () async {
            provider.startPolling();
            await Future.delayed(const Duration(seconds: 2));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Bot Controls ──
              Row(children: [
                Expanded(
                  child: _ActionButton(
                    label: 'START BOT',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF00C087),
                    onTap: provider.isRunning ? null : provider.startBot,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'STOP BOT',
                    icon: Icons.stop_rounded,
                    color: Colors.red,
                    onTap: provider.isRunning ? provider.stopBot : null,
                  ),
                ),
              ]),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  provider.statusMsg,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic),
                ),
              ),

              const SizedBox(height: 20),

              // ── Stats Grid ──
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    label: 'Account Balance',
                    value:
                        '\$${provider.balance.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF0066FF),
                  ),
                  _StatCard(
                    label: 'Open Positions',
                    value: '${provider.positions.length}',
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFFFF9800),
                  ),
                  _StatCard(
                    label: 'Total Trades',
                    value: '${provider.trades.length}',
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF9C27B0),
                  ),
                  _StatCard(
                    label: 'Unrealised PnL',
                    value:
                        '${provider.totalPnL >= 0 ? '+' : ''}\$${provider.totalPnL.toStringAsFixed(2)}',
                    icon: Icons.trending_up_rounded,
                    iconColor: provider.totalPnL >= 0
                        ? const Color(0xFF00C087)
                        : Colors.red,
                    valueColor: provider.totalPnL >= 0
                        ? const Color(0xFF00C087)
                        : Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Open Positions ──
              _SectionTitle(
                  title: 'Open Positions',
                  count: provider.positions.length),
              const SizedBox(height: 10),

              if (provider.positions.isEmpty)
                _EmptyCard(
                    icon: Icons.hourglass_empty_rounded,
                    message: 'No open positions\nWaiting for signals...')
              else
                ...provider.positions.values
                    .map((p) => _PositionCard(pos: p)),

              const SizedBox(height: 24),

              // ── Recent Trades ──
              _SectionTitle(
                  title: 'Recent Trades', count: provider.trades.length),
              const SizedBox(height: 10),

              if (provider.trades.isEmpty)
                _EmptyCard(
                    icon: Icons.swap_horiz_rounded,
                    message: 'No trades yet\nStart bot to begin trading')
              else
                ...provider.trades
                    .take(15)
                    .map((t) => _TradeCard(trade: t)),

              const SizedBox(height: 20),

              // ── Last Update ──
              Center(
                child: Text(
                  'Last updated: ${provider.lastUpdate}   •   Pull to refresh',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

// ================================================================
// ACTION BUTTON
// ================================================================
class _ActionButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.15) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: enabled ? color : Colors.grey[800]!, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              color: enabled ? color : Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: enabled ? color : Colors.grey[600]),
          ),
        ]),
      ),
    );
  }
}

// ================================================================
// STAT CARD
// ================================================================
class _StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   iconColor;
  final Color?  valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey[500])),
              const SizedBox(height: 3),
              Text(value,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SECTION TITLE
// ================================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  final int    count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C087).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C087))),
          ),
        ]);
  }
}

// ================================================================
// EMPTY CARD
// ================================================================
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String   message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.grey[700], size: 32),
        const SizedBox(height: 10),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
      ]),
    );
  }
}

// ================================================================
// POSITION CARD
// ================================================================
class _PositionCard extends StatelessWidget {
  final Position pos;

  const _PositionCard({required this.pos});

  @override
  Widget build(BuildContext context) {
    final isLong  = pos.side == 'buy' || pos.side == 'long';
    final color   = isLong ? const Color(0xFF00C087) : Colors.red;
    final pnlPos  = pos.unrealizedPnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                Icon(isLong ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color, size: 12),
                const SizedBox(width: 4),
                Text(isLong ? 'LONG' : 'SHORT',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(width: 10),
            Text(
              pos.symbol.replaceAll('USDT', '/USDT'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14),
            ),
          ]),
          Text(
            '${pnlPos ? '+' : ''}\$${pos.unrealizedPnl.toStringAsFixed(2)}',
            style: TextStyle(
                color: pnlPos ? const Color(0xFF00C087) : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          _PositionDetail(label: 'Size', value: pos.contracts.toString()),
          _PositionDetail(
              label: 'Entry',
              value: '\$${pos.entryPrice.toStringAsFixed(2)}'),
          if (pos.stopLoss > 0)
            _PositionDetail(
                label: 'SL',
                value: '\$${pos.stopLoss.toStringAsFixed(2)}',
                valueColor: Colors.red),
          if (pos.takeProfit > 0)
            _PositionDetail(
                label: 'TP',
                value: '\$${pos.takeProfit.toStringAsFixed(2)}',
                valueColor: const Color(0xFF00C087)),
        ]),
      ]),
    );
  }
}

class _PositionDetail extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PositionDetail({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.white)),
      ]),
    );
  }
}

// ================================================================
// TRADE CARD
// ================================================================
class _TradeCard extends StatelessWidget {
  final Trade trade;

  const _TradeCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isLong = trade.direction == 'LONG';
    final color  = isLong ? const Color(0xFF00C087) : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(
            isLong ? Icons.arrow_circle_up : Icons.arrow_circle_down,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              trade.symbol.replaceAll('USDT', '/USDT'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13),
            ),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(isLong ? 'BUY' : 'SELL',
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text('Qty: ${trade.quantity}',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 10)),
            ]),
          ]),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${trade.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 2),
          Text(trade.timestamp,
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ]),
      ]),
    );
  }
}
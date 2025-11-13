import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../services/crypto_service.dart';

class CryptoPage extends StatefulWidget {
  const CryptoPage({super.key});

  @override
  State<CryptoPage> createState() => _CryptoPageState();
}

class _CryptoPageState extends State<CryptoPage> {
  Map<String, dynamic>? cryptoPrices;
  Map<String, List<CandleData>> cryptoCharts = {};
  bool isLoading = true;

  final List<String> cryptoList = ['bitcoin', 'ethereum', 'dogecoin'];
  final String vsCurrency = 'usd';

  // Icônes et couleurs pour chaque crypto
  final Map<String, IconData> cryptoIcons = {
    'bitcoin': Icons.currency_bitcoin,
    'ethereum': Icons.currency_exchange,
    'dogecoin': Icons.pets,
  };

  final Map<String, Color> cryptoColors = {
    'bitcoin': const Color(0xFFF7931A),
    'ethereum': const Color(0xFF627EEA),
    'dogecoin': const Color(0xFFC2A633),
  };

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      // Prix actuels
      final prices = await CryptoService.getCryptoPrices(
        ids: cryptoList,
        vsCurrencies: [vsCurrency],
      );

      // Graphiques historiques
      Map<String, List<CandleData>> charts = {};
      for (String crypto in cryptoList) {
        final data = await CryptoService.getHistoricalData(crypto, vsCurrency, 7);
        charts[crypto] = data
            .map((e) => CandleData(
                  DateTime.fromMillisecondsSinceEpoch((e['time'] as num).toInt()),
                  (e['open'] as num).toDouble(),
                  (e['high'] as num).toDouble(),
                  (e['low'] as num).toDouble(),
                  (e['close'] as num).toDouble(),
                ))
            .toList();
      }

      setState(() {
        cryptoPrices = prices;
        cryptoCharts = charts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint(e.toString());
    }
  }

  double _calculateChange(List<CandleData> candles) {
    if (candles.isEmpty) return 0;
    final firstPrice = candles.first.open;
    final lastPrice = candles.last.close;
    if (firstPrice == 0) return 0; // évite division par zéro
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Crypto Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E1E2E),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchAllData,
              color: const Color(0xFF1E1E2E),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: cryptoList.map((crypto) {
                  // Cast explicite en double pour éviter les erreurs de type si l'API retourne un int
                  final price = (cryptoPrices![crypto][vsCurrency] as num).toDouble();
                  final candles = cryptoCharts[crypto]!;
                  final change = _calculateChange(candles);
                  final isPositive = change >= 0;

                  return _buildCryptoCard(
                    crypto: crypto,
                    price: price,
                    candles: candles,
                    change: change,
                    isPositive: isPositive,
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildCryptoCard({
    required String crypto,
    required double price,
    required List<CandleData> candles,
    required double change,
    required bool isPositive,
  }) {
    final cryptoColor = cryptoColors[crypto] ?? Colors.blue;
    final cryptoIcon = cryptoIcons[crypto] ?? Icons.currency_bitcoin;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              cryptoColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône et nom
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cryptoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cryptoIcon,
                      color: cryptoColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crypto.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _getCryptoFullName(crypto),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de changement
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prix actuel
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: cryptoColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'USD',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info High/Low
              Row(
                children: [
                  _buildPriceInfo(
                    'High',
                    candles.isNotEmpty
                        ? candles.map((e) => e.high).reduce((a, b) => a > b ? a : b)
                        : 0,
                    Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _buildPriceInfo(
                    'Low',
                    candles.isNotEmpty
                        ? candles.map((e) => e.low).reduce((a, b) => a < b ? a : b)
                        : 0,
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Titre du graphique
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7 Days Chart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Candlestick',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Graphique
              GestureDetector(
                onTap: () => _showFullScreenChart(
                  context,
                  crypto,
                  candles,
                  cryptoColor,
                  price,
                  change,
                  isPositive,
                ),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SfCartesianChart(
                          plotAreaBorderWidth: 0,
                          primaryXAxis: DateTimeAxis(
                            majorGridLines: const MajorGridLines(width: 0),
                            axisLine: const AxisLine(width: 0),
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          primaryYAxis: NumericAxis(
                            majorGridLines: MajorGridLines(
                              width: 1,
                              color: Colors.grey[200],
                            ),
                            axisLine: const AxisLine(width: 0),
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          series: <CandleSeries>[
                            CandleSeries<CandleData, DateTime>(
                              dataSource: candles,
                              xValueMapper: (CandleData data, _) => data.time,
                              lowValueMapper: (CandleData data, _) => data.low,
                              highValueMapper: (CandleData data, _) => data.high,
                              openValueMapper: (CandleData data, _) => data.open,
                              closeValueMapper: (CandleData data, _) => data.close,
                              bearColor: Colors.red[400]!,
                              bullColor: Colors.green[400]!,
                              enableSolidCandles: true,
                            )
                          ],
                        ),
                      ),
                      // Icône pour indiquer qu'on peut cliquer
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getCryptoFullName(String crypto) {
    switch (crypto.toLowerCase()) {
      case 'bitcoin':
        return 'Bitcoin';
      case 'ethereum':
        return 'Ethereum';
      case 'dogecoin':
        return 'Dogecoin';
      default:
        return crypto;
    }
  }

  void _showFullScreenChart(
      BuildContext context,
      String crypto,
      List<CandleData> candles,
      Color cryptoColor,
      double price,
      double change,
      bool isPositive,
      ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cryptoColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      cryptoIcons[crypto] ?? Icons.currency_bitcoin,
                      color: cryptoColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crypto.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              color: cryptoColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isPositive ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${change.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),

              // Graphique en grand
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SfCartesianChart(
                    title: ChartTitle(
                      text: '7 Days Performance',
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    plotAreaBorderWidth: 0,
                    primaryXAxis: DateTimeAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(width: 0),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: MajorGridLines(
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      axisLine: const AxisLine(width: 0),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2),
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      header: crypto.toUpperCase(),
                      format: 'Date: point.x\nHigh: \$point.high\nLow: \$point.low\nOpen: \$point.open\nClose: \$point.close',
                    ),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: true,
                      enableDoubleTapZooming: true,
                      enablePanning: true,
                    ),
                    series: <CandleSeries>[
                      CandleSeries<CandleData, DateTime>(
                        dataSource: candles,
                        xValueMapper: (CandleData data, _) => data.time,
                        lowValueMapper: (CandleData data, _) => data.low,
                        highValueMapper: (CandleData data, _) => data.high,
                        openValueMapper: (CandleData data, _) => data.open,
                        closeValueMapper: (CandleData data, _) => data.close,
                        bearColor: Colors.red[400]!,
                        bullColor: Colors.green[400]!,
                        enableSolidCandles: true,
                        enableTooltip: true,
                      )
                    ],
                  ),
                ),
              ),

              // Info supplémentaires
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'High',
                        '\$${candles.map((e) => e.high).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
                        Colors.green,
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Low',
                        '\$${candles.map((e) => e.low).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}',
                        Colors.red,
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Volume',
                        '${candles.length} Days',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Modèle pour les bougies
class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData(this.time, this.open, this.high, this.low, this.close);
}
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
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
        // Transformer en CandleData
        charts[crypto] = data
            .map((e) => CandleData(
          DateTime.fromMillisecondsSinceEpoch(e['time']),
          e['open'],
          e['high'],
          e['low'],
          e['close'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crypto Dashboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: cryptoList.map((crypto) {
          final price = cryptoPrices![crypto][vsCurrency];
          final candles = cryptoCharts[crypto]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crypto.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current Price: \$${price.toString()}',
                    style:
                    const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(),
                      series: <CandleSeries>[
                        CandleSeries<CandleData, DateTime>(
                          dataSource: candles,
                          xValueMapper: (CandleData data, _) => data.time,
                          lowValueMapper: (CandleData data, _) => data.low,
                          highValueMapper: (CandleData data, _) => data.high,
                          openValueMapper: (CandleData data, _) => data.open,
                          closeValueMapper: (CandleData data, _) => data.close,
                          bearColor: Colors.red,
                          bullColor: Colors.green,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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

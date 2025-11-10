import 'package:flutter/material.dart';
import '../../services/quote_api_service.dart';
import '../../pages/api_dev_page.dart';

class QuoteBanner extends StatefulWidget {
  const QuoteBanner({super.key});

  @override
  State<QuoteBanner> createState() => _QuoteBannerState();
}

class _QuoteBannerState extends State<QuoteBanner> {
  late Future<String> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _quoteFuture = QuoteApiService.fetchThemedQuote('goals');
  }

  void _refresh() {
    // update the future synchronously
    setState(() {
      _quoteFuture = QuoteApiService.fetchThemedQuote('goals');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _quoteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
        }
        final text = snapshot.data ?? 'Save consistently. Small steps add up.';
        return GestureDetector(
          onLongPress: () {
            // Hidden dev page (only if exists)
            try {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiDevPage()));
            } catch (_) {}
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(74, 144, 226, 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: Text(text, style: const TextStyle(fontStyle: FontStyle.italic))),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _refresh,
                  tooltip: 'Refresh quote',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
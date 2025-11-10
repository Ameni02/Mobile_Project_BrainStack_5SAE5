import 'package:flutter/material.dart';
import '../../services/exchange_rate_service.dart';

/// Widget that displays an amount in base currency and (optionally) the converted amount
/// into one or several target currencies. If all targets equal the source currency the widget only shows the base formatted value.
class ConvertedAmount extends StatefulWidget {
  final double amount;
  final String fromCurrency; // e.g. "TND"
  final String? toCurrency; // kept for backward compatibility
  final List<String>? toCurrencies; // new: list of target currencies
  final TextStyle? style;

  const ConvertedAmount({
    Key? key,
    required this.amount,
    required this.fromCurrency,
    this.toCurrency,
    this.toCurrencies,
    this.style,
  })  : assert(toCurrency != null || (toCurrencies != null && toCurrencies.length > 0), 'Provide toCurrency or toCurrencies'),
        super(key: key);

  @override
  State<ConvertedAmount> createState() => _ConvertedAmountState();
}

class _ConvertedAmountState extends State<ConvertedAmount> {
  late Future<List<double?>?> _convertedFuture;

  List<String> get _targets {
    if (widget.toCurrencies != null && widget.toCurrencies!.isNotEmpty) return widget.toCurrencies!.map((s) => s.toUpperCase()).toList();
    if (widget.toCurrency != null) return [widget.toCurrency!.toUpperCase()];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadConverted();
  }

  void _loadConverted() {
    final targets = _targets;
    if (targets.isEmpty || (targets.length == 1 && targets.first == widget.fromCurrency.toUpperCase())) {
      _convertedFuture = Future.value(null);
      return;
    }

    _convertedFuture = (() async {
      try {
        final results = await Future.wait<double?>(targets.map((t) async {
          if (t == widget.fromCurrency.toUpperCase()) return null;
          try {
            final v = await ExchangeRateService.convert(widget.amount, widget.fromCurrency, t);
            return v;
          } catch (_) {
            return null;
          }
        }));
        return results;
      } catch (_) {
        return List<double?>.filled(targets.length, null);
      }
    })();
  }

  @override
  void didUpdateWidget(covariant ConvertedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount || oldWidget.fromCurrency != widget.fromCurrency || oldWidget.toCurrency != widget.toCurrency || oldWidget.toCurrencies != widget.toCurrencies) {
      _loadConverted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = '${widget.fromCurrency.toUpperCase()} ${widget.amount.toStringAsFixed(2)}';
    final style = widget.style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final targets = _targets;

    return FutureBuilder<List<double?>?>(
      future: _convertedFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Text(base, style: style);
        }
        final convertedList = snap.data;
        if (convertedList == null || convertedList.every((v) => v == null)) {
          return Text(base, style: style);
        }

        // Build lines: base then each converted value (if available)
        final children = <Widget>[Text(base, style: style)];
        for (var i = 0; i < targets.length; i++) {
          final v = convertedList.length > i ? convertedList[i] : null;
          if (v == null) continue;
          children.add(Text('${targets[i]} ${v.toStringAsFixed(2)}', style: style.copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: children,
        );
      },
    );
  }
}

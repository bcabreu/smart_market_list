import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaxRateNotifier extends StateNotifier<double> {
  TaxRateNotifier() : super(0.0) {
    _loadTaxRate();
  }

  Future<void> _loadTaxRate() async {
    if (Hive.isBoxOpen('settings')) {
      final box = Hive.box('settings');
      state = box.get('tax_rate', defaultValue: 0.0);
    } else {
       // Ideally wait for box, but for now default 0.0
       // The main.dart usually opens boxes.
       final box = await Hive.openBox('settings');
       state = box.get('tax_rate', defaultValue: 0.0);
    }
  }

  Future<void> setTaxRate(double rate) async {
    state = rate;
    final box = await Hive.openBox('settings');
    await box.put('tax_rate', rate);
  }
}

final taxRateProvider = StateNotifierProvider<TaxRateNotifier, double>((ref) {
  return TaxRateNotifier();
});

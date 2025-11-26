import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_contabilidad/core/utils/constants.dart';
import 'package:app_contabilidad/core/utils/logger.dart';

/// Servicio para gestión de múltiples monedas
class CurrencyService {
  static const String _currencyKey = 'selected_currency';
  static const String _exchangeRateKey = 'exchange_rates';

  /// Monedas soportadas
  static const Map<String, String> supportedCurrencies = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'MXN': '\$',
    'ARS': '\$',
    'CLP': '\$',
    'COP': '\$',
    'PEN': 'S/',
    'BRL': 'R\$',
  };

  /// Obtiene la moneda seleccionada
  Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'USD';
  }

  /// Establece la moneda seleccionada
  Future<void> setSelectedCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCode);
  }

  /// Obtiene el símbolo de la moneda
  Future<String> getCurrencySymbol() async {
    final currency = await getSelectedCurrency();
    return supportedCurrencies[currency] ?? '\$';
  }

  /// Formatea un monto con la moneda seleccionada
  Future<String> formatAmount(double amount) async {
    final symbol = await getCurrencySymbol();
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  /// Convierte un monto de una moneda a otra
  Future<double> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    // TODO: Implementar conversión real usando API de tasas de cambio
    // Por ahora retorna el mismo monto
    // En producción usar: https://exchangerate-api.com o similar
    appLogger.w('Currency conversion not implemented yet');
    return amount;
  }

  /// Obtiene las tasas de cambio (cache)
  Future<Map<String, double>> getExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString(_exchangeRateKey);
    
    if (ratesJson != null) {
      // TODO: Parsear JSON de tasas de cambio
    }

    // Retornar tasas por defecto (1:1)
    return {
      'USD': 1.0,
      'EUR': 1.0,
      'GBP': 1.0,
      'MXN': 1.0,
    };
  }

  /// Actualiza las tasas de cambio
  Future<void> updateExchangeRates() async {
    // TODO: Obtener tasas de cambio desde API
    // Por ahora solo log
    appLogger.i('Exchange rates update not implemented yet');
  }
}


import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String _fromCurrency = 'XOF';
  String _toCurrency = 'EUR';
  final TextEditingController _fromController = TextEditingController(text: '10000');

  final Map<String, double> _rates = {
    'XOF': 1.0,
    'EUR': 0.00152,
    'USD': 0.00165,
    'GHS': 0.021,
    'MAD': 0.016,
    'CNY': 0.012,
  };

  final List<String> _currencies = [
    'XOF', 'EUR', 'USD', 'GHS', 'MAD', 'CNY',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fromAmount = double.tryParse(_fromController.text) ?? 0;
    final toAmount = fromAmount * _rates[_toCurrency]! / _rates[_fromCurrency]!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Convertisseur',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taux de change en temps réel',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            // From currency
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'De',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      _CurrencyDropdown(
                        value: _fromCurrency,
                        currencies: _currencies,
                        onChanged: (value) {
                          setState(() {
                            _fromCurrency = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fromController,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey[600],
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCurrencyName(_fromCurrency),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Swap button
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A0A3E),
                      Color(0xFF2A1A4A),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.arrowUpDown,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // To currency
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1A0A3E),
                    Color(0xFF2A1A4A),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vers',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      _CurrencyDropdown(
                        value: _toCurrency,
                        currencies: _currencies,
                        onChanged: (value) {
                          setState(() {
                            _toCurrency = value!;
                          });
                        },
                        isDark: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    toAmount.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCurrencyName(_toCurrency),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Rate info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  _FlagIcon(_fromCurrency),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1 $_fromCurrency = ${(_rates[_toCurrency]! / _rates[_fromCurrency]!} $_toCurrency',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mis à jour il y a 2 min · Taux indicatif',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _FlagIcon(_toCurrency),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'COURS DU XOF',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            ..._currencies.where((c) => c != 'XOF').map((currency) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      _FlagIcon(currency),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getCurrencyName(currency),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _rates[currency]!.toStringAsFixed(5),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getCurrencyName(String currency) {
    switch (currency) {
      case 'XOF': return 'Franc CFA UEMOA';
      case 'EUR': return 'Euro';
      case 'USD': return 'Dollar US';
      case 'GHS': return 'Cedi Ghanéen';
      case 'MAD': return 'Dirham Marocain';
      case 'CNY': return 'Yuan Chinois';
      default: return '';
    }
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String value;
  final List<String> currencies;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _CurrencyDropdown({
    required this.value,
    required this.currencies,
    required this.onChanged,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          items: currencies.map((String currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Row(
              children: [
                _FlagIcon(currency, size: 20),
                const SizedBox(width: 8),
                Text(currency),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

class _FlagIcon extends StatelessWidget {
  final String currency;
  final double size;

  const _FlagIcon(this.currency, {this.size = 28});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (currency) {
      case 'XOF':
        icon = Icons.currency_franc;
      case 'EUR':
        icon = Icons.euro;
      case 'USD':
        icon = Icons.attach_money;
      case 'GHS':
        icon = Icons.currency_cedi;
      case 'MAD':
        icon = Icons.currency_dirham;
      case 'CNY':
        icon = Icons.currency_yuan;
      default:
        icon = Icons.currency_exchange;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: size * 0.6,
      ),
    );
  }
}
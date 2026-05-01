import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';

class PriceText extends StatelessWidget {
  final double amount;
  final bool showCurrencyCode;
  final bool large;
  final Color? amountColor;

  const PriceText({
    super.key,
    required this.amount,
    this.showCurrencyCode = true,
    this.large = false,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = Formatters.formatCurrency(amount);
    final number = formatted.replaceFirst('UGX', '').trim();
    final amountStyle = (large
            ? AppTextStyles.priceAmountLarge
            : AppTextStyles.priceAmount)
        .copyWith(color: amountColor ?? AppTextStyles.priceAmount.color);

    if (!showCurrencyCode) {
      return Text(number, style: amountStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: 'UGX ', style: AppTextStyles.currencyCode),
          TextSpan(text: number, style: amountStyle),
        ],
      ),
    );
  }
}

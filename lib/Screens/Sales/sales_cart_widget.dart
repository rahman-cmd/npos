import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_pos/Screens/Sales/provider/sales_cart_provider.dart';
import 'package:mobile_pos/Screens/Sales/sales_add_to_cart_sales_widget.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

class SalesCartListWidget extends ConsumerWidget {
  const SalesCartListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerData = ref.watch(cartNotifier);
    final s = lang.S.of(context);
    final _theme = Theme.of(context);
    return providerData.cartItemList.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                collapsedBackgroundColor: kMainColor2,
                backgroundColor: kMainColor2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: kLineColor,
                    width: 1,
                  ),
                ),
                title: Text(
                  lang.S.of(context).itemAdded,
                  style: _theme.textTheme.titleMedium,
                ),
                children: [
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: providerData.cartItemList.length,
                      itemBuilder: (context, index) {
                        final item = providerData.cartItemList[index];

                        // Calculate values for display
                        final double quantity = item.quantity.toDouble();
                        final double unitPrice = (item.unitPrice ?? 0).toDouble();
                        final double discountPerUnit = (item.discountAmount ?? 0).toDouble();
                        final double totalDiscount = quantity * discountPerUnit;
                        final double subTotal = quantity * unitPrice;
                        final double finalTotal = subTotal - totalDiscount;

                        return ListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 10),
                          onTap: () => showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (context2) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          s.updateProduct,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        CloseButton(
                                          onPressed: () => Navigator.pop(context2),
                                        )
                                      ],
                                    ),
                                  ),
                                  const Divider(thickness: 1, color: kBorderColorTextField),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SalesAddToCartForm(
                                      batchWiseStockModel: item,
                                      previousContext: context2,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          title: Text(
                            item.productName.toString(),
                            style: _theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                // Qty X Price
                                TextSpan(
                                  text: '${formatPointNumber(quantity)} X $unitPrice ',
                                  style: _theme.textTheme.titleSmall?.copyWith(
                                    color: kPeraColor,
                                  ),
                                ),
                                // Show Discount if exists
                                if (totalDiscount > 0)
                                  TextSpan(
                                    text: '- ${formatPointNumber(totalDiscount)} (Disc) ',
                                    style: _theme.textTheme.titleSmall?.copyWith(
                                      color: kPeraColor,
                                    ),
                                  ),
                                // Final Total
                                TextSpan(
                                  text: '= ${formatPointNumber(finalTotal)} ',
                                  style: _theme.textTheme.titleSmall?.copyWith(
                                    color: kTitleColor,
                                  ),
                                ),
                                // Batch Info
                                if (item.productType == 'variant')
                                  TextSpan(
                                    text: '[${item.batchName}]',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 90,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => providerData.quantityDecrease(index),
                                      child: Container(
                                        height: 18,
                                        width: 18,
                                        decoration: const BoxDecoration(
                                          color: kMainColor,
                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.remove, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      width: 40,
                                      child: Center(
                                        child: Text(
                                          formatPointNumber(item.quantity),
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: kGreyTextColor,
                                              ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => providerData.quantityIncrease(index),
                                      child: Container(
                                        height: 18,
                                        width: 18,
                                        decoration: const BoxDecoration(
                                          color: kMainColor,
                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.add, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => providerData.deleteToCart(index),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedDelete03,
                                  size: 20,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        : SizedBox.shrink();
  }
}

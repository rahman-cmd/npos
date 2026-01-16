import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Sales/provider/sales_cart_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as l;
import 'package:mobile_pos/model/add_to_cart_model.dart';

import '../../constant.dart';

class SalesAddToCartForm extends StatefulWidget {
  const SalesAddToCartForm({
    super.key,
    required this.batchWiseStockModel,
    required this.previousContext,
  });

  final SaleCartModel batchWiseStockModel;
  final BuildContext previousContext;

  @override
  ProductAddToCartFormState createState() => ProductAddToCartFormState();
}

class ProductAddToCartFormState extends State<SalesAddToCartForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController productQuantityController;
  late TextEditingController discountController;
  late TextEditingController salePriceController;

  bool isClicked = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    salePriceController = TextEditingController(
      text: widget.batchWiseStockModel.unitPrice.toString(),
    );
    productQuantityController = TextEditingController(
      text: formatPointNumber(widget.batchWiseStockModel.quantity),
    );
    discountController = TextEditingController(
      text: widget.batchWiseStockModel.discountAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    productQuantityController.dispose();
    discountController.dispose();
    salePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, __) {
      final lang = l.S.of(context);

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Quantity and Price Row ---
            Row(
              children: [
                // Quantity Field
                Expanded(
                  child: TextFormField(
                    controller: productQuantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      final qty = num.tryParse(value ?? '') ?? 0;

                      // 1. Check for basic valid quantity
                      if (value == null || value.isEmpty || qty <= 0) {
                        return lang.enterQuantity;
                      }

                      // 2. Check Stock (Skip check if it is a Combo product)
                      final isCombo = widget.batchWiseStockModel.productType?.toLowerCase().contains('combo') ?? false;
                      final currentStock = widget.batchWiseStockModel.stock ?? 0;

                      if (!isCombo && qty > currentStock) {
                        return lang.outOfStock;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      label: Text(lang.quantity),
                      hintText: lang.enterQuantity,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Sale Price Field
                Expanded(
                  child: TextFormField(
                    controller: salePriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.pleaseEnterAValidSalePrice;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      label: Text(lang.salePrice),
                      hintText: lang.enterAmount,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- Discount Field ---
            TextFormField(
              controller: discountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final discount = num.tryParse(value) ?? 0;
                  final price = num.tryParse(salePriceController.text) ?? 0;

                  if (discount < 0) {
                    return lang.enterAValidDiscount; // Or "Discount cannot be negative"
                  }
                  // Validation: Discount cannot be greater than the unit price
                  if (discount > price) {
                    return '${lang.discount} > ${lang.salePrice}';
                  }
                }
                return null;
              },
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.always,
                label: Text(lang.discount),
                hintText: lang.enterAValidDiscount,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              ),
            ),
            const SizedBox(height: 29),

            // --- Save Button ---
            GestureDetector(
              onTap: () async {
                if (isClicked) return;

                if (_formKey.currentState?.validate() ?? false) {
                  setState(() {
                    isClicked = true;
                  });

                  ref.read(cartNotifier).updateProduct(
                        productId: widget.batchWiseStockModel.productId,
                        price: salePriceController.text,
                        qty: productQuantityController.text,
                        discount: num.tryParse(discountController.text) ?? 0,
                      );

                  Navigator.pop(context);
                }
              },
              child: Container(
                height: 48,
                decoration: const BoxDecoration(
                  color: kMainColor,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child: Text(
                    lang.save,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            )
          ],
        ),
      );
    });
  }
}

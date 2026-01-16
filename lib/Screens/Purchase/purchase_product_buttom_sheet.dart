import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

// Adjust imports to match your project structure
import '../../Provider/add_to_cart_purchase.dart';
import '../../Provider/product_provider.dart';
import '../../constant.dart';
import '../Products/Model/product_model.dart';
import '../Products/Repo/product_repo.dart';
import '../../service/check_user_role_permission_provider.dart';
import '../Products/add product/modle/create_product_model.dart';
import '../warehouse/warehouse_model/warehouse_list_model.dart';
import '../warehouse/warehouse_provider/warehouse_provider.dart';
import 'Repo/purchase_repo.dart';

Future<void> addProductInPurchaseCartButtomSheet({
  required BuildContext context,
  required CartProductModelPurchase product,
  required WidgetRef ref,
  required bool fromUpdate,
  required int index,
  required bool fromStock,
  required List<Stock> stocks,
}) {
  final theme = Theme.of(context);
  final permissionService = PermissionService(ref);
  final decimalInputFormatter = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController productStockController = TextEditingController(text: product.quantities.toString());
  final TextEditingController salePriceController = TextEditingController(text: '${product.productSalePrice}');
  final TextEditingController purchaseExclusivePriceController = TextEditingController(
      text: product.vatType == 'exclusive'
          ? '${product.productPurchasePrice}'
          : '${((product.productPurchasePrice ?? 0) / (1 + product.vatRate / 100))}');
  final TextEditingController profitMarginController = TextEditingController(text: '${product.profitPercent}');
  final TextEditingController purchaseInclusivePriceController = TextEditingController();
  final TextEditingController wholeSalePriceController =
      TextEditingController(text: '${product.productWholeSalePrice}');
  final TextEditingController dealerPriceController = TextEditingController(text: '${product.productDealerPrice}');
  final TextEditingController expireDateController = TextEditingController(text: product.expireDate ?? '');
  final TextEditingController manufactureDateController = TextEditingController(text: product.mfgDate ?? '');
  final TextEditingController productBatchNumberController = TextEditingController(text: product.batchNumber ?? '');

  // Initialization variables
  bool isCalculated = false;

  // These will be managed inside the StatefulBuilder
  num? selectedWarehouseId = product.warehouseId;
  Stock? selectedStock;

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final warehouseAsyncValue = ref.watch(fetchWarehouseListProvider);

          return warehouseAsyncValue.when(
            loading: () => Padding(
              padding: const EdgeInsets.all(30.0),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(30.0),
              child: Center(child: Text('Error loading warehouses: $err')),
            ),
            data: (warehouseModel) {
              final warehouseList = warehouseModel.data ?? [];

              return StatefulBuilder(
                builder: (context, setState) {
                  // --- PRICE CALCULATION FUNCTION ---
                  void calculatePurchaseAndMrp({String? from}) {
                    num purchaseExc = 0;
                    num purchaseInc = 0;
                    num profitMargin = num.tryParse(profitMarginController.text) ?? 0;
                    num salePrice = 0;

                    if (from == 'purchase_inc') {
                      purchaseExc = (num.tryParse(purchaseInclusivePriceController.text) ?? 0) /
                          (1 + (product.vatRate ?? 0) / 100);
                      purchaseExclusivePriceController.text = purchaseExc.toStringAsFixed(2);
                    } else {
                      purchaseExc = num.tryParse(purchaseExclusivePriceController.text) ?? 0;
                      purchaseInc = purchaseExc + (purchaseExc * (product.vatRate ?? 0) / 100);
                      purchaseInclusivePriceController.text = purchaseInc.toStringAsFixed(2);
                    }

                    purchaseInc = num.tryParse(purchaseInclusivePriceController.text) ?? 0;

                    if (from == 'mrp') {
                      salePrice = num.tryParse(salePriceController.text) ?? 0;
                      num costPrice = (product.vatType.toLowerCase() == 'exclusive' ? purchaseExc : purchaseInc);

                      if (costPrice > 0) {
                        profitMargin = ((salePrice - costPrice) / costPrice) * 100;
                        profitMarginController.text = profitMargin.toStringAsFixed(2);
                      }
                    } else {
                      salePrice = (product.vatType.toLowerCase() == 'exclusive')
                          ? purchaseExc + (purchaseExc * profitMargin / 100)
                          : purchaseInc + (purchaseInc * profitMargin / 100);
                      salePriceController.text = salePrice.toStringAsFixed(2);
                    }
                    // No setState needed here if called inside setState,
                    // but needed if called from TextField onChanged outside build
                  }

                  // Helper to populate fields from a Stock object
                  void populateFieldsFromStock(Stock stock) {
                    productBatchNumberController.text = stock.batchNo ?? '';

                    // Update Prices
                    purchaseExclusivePriceController.text = stock.productPurchasePrice?.toString() ?? '0';
                    salePriceController.text = stock.productSalePrice?.toString() ?? '0';
                    wholeSalePriceController.text = stock.productWholeSalePrice?.toString() ?? '0';
                    dealerPriceController.text = stock.productDealerPrice?.toString() ?? '0';

                    // Update Dates
                    manufactureDateController.text = stock.mfgDate ?? '';
                    expireDateController.text = stock.expireDate ?? '';

                    // Recalculate Inclusive Price based on new Exclusive Price
                    num purchaseExc = stock.productPurchasePrice ?? 0;
                    num purchaseInc = purchaseExc + (purchaseExc * (product.vatRate ?? 0) / 100);
                    purchaseInclusivePriceController.text = purchaseInc.toStringAsFixed(2);

                    // Recalculate Margin based on new Sale Price
                    num salePrice = stock.productSalePrice ?? 0;
                    num costPrice = (product.vatType.toLowerCase() == 'exclusive' ? purchaseExc : purchaseInc);

                    if (costPrice > 0) {
                      num profitMargin = ((salePrice - costPrice) / costPrice) * 100;
                      profitMarginController.text = profitMargin.toStringAsFixed(2);
                    } else {
                      profitMarginController.text = '0';
                    }
                  }

                  // --- 1. INITIALIZATION LOGIC (Runs once) ---
                  if (!isCalculated) {
                    // A. Calculate Initial Inclusive Price
                    num purchaseExc = num.tryParse(purchaseExclusivePriceController.text) ?? 0;
                    num purchaseInc = purchaseExc + (purchaseExc * (product.vatRate ?? 0) / 100);
                    purchaseInclusivePriceController.text = purchaseInc.toStringAsFixed(2);

                    // B. Auto-Select Stock based on matching Batch Number
                    try {
                      if (product.batchNumber != null && product.batchNumber!.isNotEmpty) {
                        selectedStock = stocks.firstWhere(
                          (element) => element.batchNo == product.batchNumber,
                        );
                        // Optional: If you want to force update fields on load from the matched stock:
                        // if(selectedStock != null) populateFieldsFromStock(selectedStock!);
                      }
                    } catch (e) {
                      selectedStock = null;
                    }

                    // C. Auto-Select Warehouse
                    if (selectedStock != null) {
                      selectedWarehouseId = selectedStock!.warehouseId;
                    } else {
                      selectedWarehouseId = product.warehouseId;
                    }

                    isCalculated = true;
                  }

                  // --- 3. SAFETY CHECK ---
                  if (selectedStock != null) {
                    bool existsInFilter = stocks.any((element) => element.id == selectedStock!.id);
                    if (!existsInFilter) {
                      selectedStock = null;
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(lang.S.of(context).addVariantDetails, style: theme.textTheme.titleMedium),
                                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close)),
                                ],
                              ),
                              Divider(color: kBorderColor),
                              const SizedBox(height: 12),

                              // ---------------- WAREHOUSE & STOCK SECTION ----------------
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Warehouse Dropdown
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lang.S.of(context).warehouse,
                                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        SizedBox(height: 5),
                                        DropdownButtonFormField<num>(
                                          value: selectedWarehouseId,
                                          isExpanded: true,
                                          decoration: kInputDecoration.copyWith(
                                            hintText: lang.S.of(context).select,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          ),
                                          items: warehouseList.map((WarehouseData warehouse) {
                                            return DropdownMenuItem<num>(
                                              value: warehouse.id,
                                              child: Text(
                                                warehouse.name ?? 'Unknown',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedWarehouseId = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Stock Dropdown (Auto-Populate Logic Here)
                                  if (product.productType != 'single') ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lang.S.of(context).stockOrVariant,
                                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          SizedBox(height: 5),
                                          DropdownButtonFormField<Stock>(
                                            value: selectedStock,
                                            isExpanded: true,
                                            decoration: kInputDecoration.copyWith(
                                              hintText: lang.S.of(context).selectStock,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                            ),
                                            items: stocks.map((stock) {
                                              String displayName = stock.batchNo ?? lang.S.of(context).noBatch;
                                              if (stock.variantName != null && stock.variantName!.isNotEmpty) {
                                                displayName = "${stock.variantName} ($displayName)";
                                              }
                                              return DropdownMenuItem<Stock>(
                                                value: stock,
                                                child: Text(
                                                  displayName,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (Stock? value) {
                                              setState(() {
                                                selectedStock = value;
                                                if (value != null) {
                                                  // Call helper to update UI controllers
                                                  populateFieldsFromStock(value);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              // ---------------- END WAREHOUSE & STOCK SECTION ----------------

                              Row(
                                spacing: 12,
                                children: [
                                  if (product.productType == ProductType.variant.name)
                                    Expanded(
                                      child: TextFormField(
                                        controller: productBatchNumberController,
                                        decoration: kInputDecoration.copyWith(
                                          labelText: lang.S.of(context).batchNo,
                                          hintText: lang.S.of(context).enterBatchNo,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: productStockController,
                                      inputFormatters: decimalInputFormatter,
                                      keyboardType: TextInputType.number,
                                      decoration: kInputDecoration.copyWith(
                                        labelText: lang.S.of(context).quantity,
                                        hintText: lang.S.of(context).enterQuantity,
                                      ),
                                      validator: (value) {
                                        if ((num.tryParse(value ?? '') ?? 0) <= 0) {
                                          return lang.S.of(context).purchaseQuantityRequired;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (permissionService.hasPermission(Permit.purchasesPriceView.value)) ...{
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: purchaseExclusivePriceController,
                                        onChanged: (value) {
                                          setState(() {
                                            calculatePurchaseAndMrp();
                                          });
                                        },
                                        inputFormatters: decimalInputFormatter,
                                        keyboardType: TextInputType.number,
                                        decoration: kInputDecoration.copyWith(
                                          labelText: lang.S.of(context).purchaseEx,
                                          hintText: lang.S.of(context).enterPurchasePrice,
                                        ),
                                        validator: (value) {
                                          if ((num.tryParse(value ?? '') ?? 0) <= 0) {
                                            return lang.S.of(context).purchaseExReq;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: purchaseInclusivePriceController,
                                        onChanged: (value) {
                                          setState(() {
                                            calculatePurchaseAndMrp(from: "purchase_inc");
                                          });
                                        },
                                        inputFormatters: decimalInputFormatter,
                                        keyboardType: TextInputType.number,
                                        decoration: kInputDecoration.copyWith(
                                          labelText: lang.S.of(context).purchaseIn,
                                          hintText: lang.S.of(context).enterSaltingPrice,
                                        ),
                                        validator: (value) {
                                          if ((num.tryParse(value ?? '') ?? 0) <= 0) {
                                            return lang.S.of(context).purchaseInReq;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              },
                              Row(
                                children: [
                                  if (permissionService.hasPermission(Permit.purchasesPriceView.value)) ...{
                                    Expanded(
                                      child: TextFormField(
                                        controller: profitMarginController,
                                        onChanged: (value) {
                                          setState(() {
                                            calculatePurchaseAndMrp();
                                          });
                                        },
                                        inputFormatters: decimalInputFormatter,
                                        keyboardType: TextInputType.number,
                                        decoration: kInputDecoration.copyWith(
                                          labelText: lang.S.of(context).profitMargin,
                                          hintText: lang.S.of(context).enterPurchasePrice,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  },
                                  Expanded(
                                    child: TextFormField(
                                      controller: salePriceController,
                                      onChanged: (value) {
                                        setState(() {
                                          calculatePurchaseAndMrp(from: 'mrp');
                                        });
                                      },
                                      inputFormatters: decimalInputFormatter,
                                      keyboardType: TextInputType.number,
                                      decoration: kInputDecoration.copyWith(
                                        labelText: lang.S.of(context).mrp,
                                        hintText: lang.S.of(context).enterSaltingPrice,
                                      ),
                                      validator: (value) {
                                        if ((num.tryParse(value ?? '') ?? 0) <= 0) {
                                          return lang.S.of(context).saleReq;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: wholeSalePriceController,
                                      inputFormatters: decimalInputFormatter,
                                      keyboardType: TextInputType.number,
                                      decoration: kInputDecoration.copyWith(
                                        labelText: lang.S.of(context).wholeSalePrice,
                                        hintText: lang.S.of(context).enterWholesalePrice,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: dealerPriceController,
                                      inputFormatters: decimalInputFormatter,
                                      keyboardType: TextInputType.number,
                                      decoration: kInputDecoration.copyWith(
                                        labelText: lang.S.of(context).dealerPrice,
                                        hintText: lang.S.of(context).enterDealerPrice,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: manufactureDateController,
                                      readOnly: true,
                                      decoration: kInputDecoration.copyWith(
                                        labelText: lang.S.of(context).manufactureDate,
                                        hintText: lang.S.of(context).selectDate,
                                        suffixIcon: IconButton(
                                          icon: Icon(IconlyLight.calendar),
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2015),
                                              lastDate: DateTime(2101),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                manufactureDateController.text = DateFormat.yMd().format(picked);
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: expireDateController,
                                      readOnly: true,
                                      decoration: kInputDecoration.copyWith(
                                        labelText: lang.S.of(context).expDate,
                                        hintText: lang.S.of(context).selectDate,
                                        suffixIcon: IconButton(
                                          icon: Icon(IconlyLight.calendar),
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2015),
                                              lastDate: DateTime(2101),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                expireDateController.text = DateFormat.yMd().format(picked);
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ButtonStyle(
                                          side: WidgetStatePropertyAll(BorderSide(color: Color(0xffF68A3D)))),
                                      child:
                                          Text(lang.S.of(context).cancel, style: TextStyle(color: Color(0xffF68A3D))),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          final cartProduct = CartProductModelPurchase(
                                              warehouseId: selectedWarehouseId,
                                              productId: product.productId ?? 0,
                                              // SAVE SELECTED STOCK ID OR ORIGINAL STOCK ID IF SINGLE
                                              variantName: product.productType == 'single'
                                                  ? (product.variantName)
                                                  : (selectedStock?.variantName ?? product.variantName),
                                              brandName: product.brandName ?? '',
                                              productName: product.productName ?? '',
                                              productType: product.productType,
                                              vatAmount: product.vatAmount,
                                              vatRate: product.vatRate,
                                              vatType: product.vatType,
                                              batchNumber: productBatchNumberController.text,
                                              productDealerPrice: num.tryParse(dealerPriceController.text),
                                              productPurchasePrice: num.tryParse(product.vatType == 'exclusive'
                                                  ? purchaseExclusivePriceController.text
                                                  : purchaseInclusivePriceController.text),
                                              productSalePrice: num.tryParse(salePriceController.text),
                                              productWholeSalePrice: num.tryParse(wholeSalePriceController.text),
                                              quantities: num.tryParse(productStockController.text),
                                              expireDate: dateFormateChange(date: expireDateController.text),
                                              mfgDate: dateFormateChange(date: manufactureDateController.text),
                                              profitPercent: num.tryParse(profitMarginController.text));

                                          if (fromStock) {
                                            ProductRepo productRepo = ProductRepo();
                                            bool success = await productRepo.updateVariation(data: cartProduct);
                                            if (success) {
                                              ref.refresh(productProvider);
                                              ref.refresh(fetchProductDetails(product.productId.toString()));
                                              Navigator.pop(context);
                                            }
                                          } else if (fromUpdate) {
                                            ref
                                                .watch(cartNotifierPurchaseNew)
                                                .updateProduct(index: index, newProduct: cartProduct);
                                            Navigator.pop(context);
                                          } else {
                                            ref.watch(cartNotifierPurchaseNew).addToCartRiverPod(
                                                cartItem: cartProduct,
                                                isVariation: product.productType == ProductType.variant.name);
                                            int count = 0;
                                            Navigator.popUntil(context, (route) {
                                              return count++ == 2;
                                            });
                                          }
                                        }
                                      },
                                      child: Text(lang.S.of(context).saveVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}

// Helper Function
String dateFormateChange({required String? date}) {
  if (date == null || date.trim().isEmpty) return '';

  try {
    DateTime parsed;
    if (date.contains('-')) {
      parsed = DateTime.parse(date);
    } else {
      parsed = DateFormat("M/d/yyyy").parse(date);
    }

    return DateFormat("yyyy-MM-dd").format(parsed);
  } catch (e) {
    print('Failed to format date: $date → $e');
    return '';
  }
}

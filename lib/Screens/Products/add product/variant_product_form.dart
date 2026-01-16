import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Screens/Products/product_setting/model/get_product_setting_model.dart';
import 'package:mobile_pos/Screens/warehouse/warehouse_model/warehouse_list_model.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../../constant.dart';
import '../../../currency.dart';
import '../../../service/check_user_role_permission_provider.dart';
import '../../product variation/model/product_variation_model.dart';
import '../../product variation/provider/product_variation_provider.dart';
import '../../vat_&_tax/model/vat_model.dart';
import '../../warehouse/warehouse_provider/warehouse_provider.dart';
import '../Widgets/acnoo_multiple_select_dropdown.dart';
import '../Widgets/dropdown_styles.dart';
import 'modle/create_product_model.dart';

class VariantProductForm extends ConsumerStatefulWidget {
  const VariantProductForm({
    super.key,
    required this.initialStocks,
    required this.onStocksUpdated,
    required this.snapShot,
    this.selectedWarehouse,
    required this.onSelectVariation,
    this.tax,
    required this.taxType,
    this.productVariationIds,
    this.productCode,
  });

  final List<StockDataModel> initialStocks;
  final Function(List<StockDataModel>) onStocksUpdated;
  final Function(List<String?>) onSelectVariation;
  final GetProductSettingModel snapShot;
  final VatModel? tax;
  final String taxType;
  final List<String>? productVariationIds;
  final String? productCode;
  // State variables passed from Parent
  final WarehouseData? selectedWarehouse; // Received from parent

  @override
  ConsumerState<VariantProductForm> createState() => _VariantProductFormState();
}

class _VariantProductFormState extends ConsumerState<VariantProductForm> {
  List<int?> selectedVariation = [];
  List<VariationData> variationList = [];
  Map<num?, List<String>?> selectedVariationValues = {};
  List<StockDataModel> localVariantStocks = [];

  bool isDataInitialized = false;

  final kLoader = const Center(child: CircularProgressIndicator(strokeWidth: 2));

  @override
  void initState() {
    super.initState();
    localVariantStocks = widget.initialStocks;
  }

  void generateVariants({bool? changeState}) {
    if (selectedVariation.isEmpty) {
      setState(() => localVariantStocks.clear());
      widget.onStocksUpdated(localVariantStocks);
      return;
    }
    // 1. Gather active Variations (No Change)
    List<VariationData> activeVariations = [];
    List<List<String>> activeValues = [];

    for (var id in selectedVariation) {
      if (id != null &&
          selectedVariationValues.containsKey(id) &&
          selectedVariationValues[id] != null &&
          selectedVariationValues[id]!.isNotEmpty) {
        var vData = variationList.firstWhere((element) => element.id == id, orElse: () => VariationData());
        if (vData.id != null) {
          activeVariations.add(vData);
          activeValues.add(selectedVariationValues[id]!);
        }
      }
    }

    if (activeVariations.isEmpty || activeValues.length != activeVariations.length) {
      setState(() => localVariantStocks = []);
      widget.onStocksUpdated(localVariantStocks);
      return;
    }
    ;

    // 2. Calculate Cartesian Product (No Change)
    List<List<String>> cartesian(List<List<String>> lists) {
      List<List<String>> result = [[]];
      for (var list in lists) {
        result = [
          for (var a in result)
            for (var b in list) [...a, b]
        ];
      }
      return result;
    }

    List<List<String>> combinations = cartesian(activeValues);
    List<StockDataModel> newStocks = [];

    String baseCode = widget.productCode ?? "";
    int counter = 1;
    for (var combo in combinations) {
      String variantName = combo.join(" - ");
      List<Map<String, String>> vData = [];
      for (int i = 0; i < combo.length; i++) {
        vData.add({activeVariations[i].name ?? '': combo[i]});
      }

      // Check if this ROOT variant already exists (to preserve edits)
      var existingIndex = localVariantStocks.indexWhere((element) => element.variantName == variantName);

      if (existingIndex != -1) {
        StockDataModel parent = localVariantStocks[existingIndex];

        // Updating batch no according to new code structure
        if (baseCode.isNotEmpty) {
          parent.batchNo = "$baseCode-$counter";
        }
        newStocks.add(parent);
      } else {
        // C. New Root Variant
        String autoBatchNo = baseCode.isNotEmpty ? "$baseCode-$counter" : "";

        newStocks.add(StockDataModel(
          profitPercent: '0',
          variantName: variantName,
          batchNo: autoBatchNo, // NEW LOGIC: 1002-1
          variationData: vData,
          productStock: "0",
          exclusivePrice: "0",
          inclusivePrice: "0",
          productSalePrice: "0",
        ));
      }
      counter++;
    }

    setState(() => localVariantStocks = newStocks);
    widget.onStocksUpdated(localVariantStocks);
  }

  // --- Logic to Initialize Data from Edit Mode ---
  void _initializeEditData(List<VariationData> allVariations) {
    if (isDataInitialized) return;
    if (localVariantStocks.isEmpty && (widget.productVariationIds == null || widget.productVariationIds!.isEmpty))
      return;

    // 1. Set Selected Variation Types (Example: Size, Color IDs)
    if (widget.productVariationIds != null) {
      selectedVariation = widget.productVariationIds!.map((e) => int.tryParse(e)).where((e) => e != null).toList();
    }

    for (final stock in localVariantStocks) {
      print('Pioewruwr------------------------> ${stock.variationData}');
      if (stock.variationData != null) {
        for (Map<String, dynamic> vMap in stock.variationData!) {
          print('$vMap');
          // vMap looks like {"Size": "M"}
          vMap.forEach((keyName, value) {
            // Find the ID associated with this Name (e.g., "Size" -> ID 1)
            final variationObj = allVariations.firstWhere(
              (element) => element.name?.toLowerCase() == keyName.toLowerCase(),
              orElse: () => VariationData(),
            );

            if (variationObj.id != null) {
              num vId = variationObj.id!;

              // Add value to the list if not exists
              if (!selectedVariationValues.containsKey(vId)) {
                selectedVariationValues[vId] = [];
              }

              if (value is String && !selectedVariationValues[vId]!.contains(value)) {
                selectedVariationValues[vId]!.add(value);
              }
            }
          });
        }
      }
    }

    isDataInitialized = true;
    Future.microtask(() => setState(() {}));
  }

  void _addSubVariation(int parentIndex) {
    final parentStock = localVariantStocks[parentIndex];

    // Ensure parent has a batch number
    if (parentStock.batchNo == null || parentStock.batchNo!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parent must have a Batch No first")));
      return;
    }

    // Count existing children to generate ID (e.g., 1001-1, 1001-2)
    final String parentBatch = parentStock.batchNo!;
    int childCount = localVariantStocks
        .where((element) => element.batchNo != null && element.batchNo!.startsWith("$parentBatch-"))
        .length;

    String newSubBatch = "$parentBatch-${childCount + 1}";

    // Create Child Stock (Copying basic data from parent if needed, or blank)
    StockDataModel childStock = StockDataModel(
      variantName: "${parentStock.variantName} (Sub ${childCount + 1})", // Indicating it's a sub
      batchNo: '',
      variationData: parentStock.variationData, // Inherit variation traits
      profitPercent: parentStock.profitPercent ?? '0',
      productStock: "0",
      exclusivePrice: parentStock.exclusivePrice ?? "0",
      inclusivePrice: parentStock.inclusivePrice ?? "0",
      productSalePrice: parentStock.productSalePrice ?? "0",
      warehouseId: parentStock.warehouseId,
    );

    setState(() {
      // Insert immediately after the parent (and its existing children)
      // We insert at parentIndex + 1 + childCount to keep them grouped
      localVariantStocks.insert(parentIndex + 1 + childCount, childStock);
    });
    widget.onStocksUpdated(localVariantStocks);
  }

  void _removeVariation(int index) {
    final stockToRemove = localVariantStocks[index];
    final String? batchNo = stockToRemove.batchNo;

    setState(() {
      localVariantStocks.removeAt(index);

      // If it was a parent, remove all its children (Sub-variations)
      if (batchNo != null && !batchNo.contains('-')) {
        localVariantStocks
            .removeWhere((element) => element.batchNo != null && element.batchNo!.startsWith("$batchNo-"));
      }
    });
    widget.onStocksUpdated(localVariantStocks);
  }

  @override
  Widget build(BuildContext context) {
    final _dropdownStyle = AcnooDropdownStyle(context);
    final variationData = ref.watch(variationListProvider);
    final _theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 24),

        //------- Variation Type Selection --------------------
        variationData.when(
          data: (variation) {
            variationList = variation.data ?? [];

            // -----------------------------------------
            // HERE IS THE FIX: Initialize Data Once
            // -----------------------------------------
            if (!isDataInitialized && variationList.isNotEmpty) {
              _initializeEditData(variationList);
            }

            return AcnooMultiSelectDropdown(
              menuItemStyleData: _dropdownStyle.multiSelectMenuItemStyle,
              buttonStyleData: _dropdownStyle.buttonStyle,
              iconStyleData: _dropdownStyle.iconStyle,
              dropdownStyleData: _dropdownStyle.dropdownStyle,
              labelText: lang.S.of(context).selectVariations,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(8),
                hintText: lang.S.of(context).selectItems,
              ),
              values: selectedVariation,
              items: variationList.map((item) {
                return MultiSelectDropdownMenuItem(value: item.id, labelText: item.name ?? '');
              }).toList(),
              onChanged: (values) {
                setState(() {
                  selectedVariation = values?.map((e) => e as int?).toList() ?? [];

                  selectedVariationValues.removeWhere((key, value) => !selectedVariation.contains(key));
                });

                widget.onSelectVariation(values?.map((e) => e.toString()).toList() ?? []);
                if (selectedVariation.isEmpty) {
                  setState(() => localVariantStocks.clear());
                  widget.onStocksUpdated(localVariantStocks);
                } else {
                  generateVariants();
                }
              },
            );
          },
          error: (e, stack) => Center(child: Text(e.toString())),
          loading: () => kLoader,
        ),

        //----------- Variation Values Selection ---------------
        if (selectedVariation.isNotEmpty) const SizedBox(height: 24),
        if (selectedVariation.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: variationList.where((item) => selectedVariation.contains(item.id)).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.8),
            itemBuilder: (context, index) {
              final filteredItems = variationList.where((item) => selectedVariation.contains(item.id)).toList();
              final varItem = filteredItems[index];
              return AcnooMultiSelectDropdown<String>(
                key: GlobalKey(debugLabel: varItem.name),
                labelText: varItem.name ?? '',
                values: selectedVariationValues[varItem.id] ?? [],
                items: (varItem.values ?? []).map((value) {
                  return MultiSelectDropdownMenuItem(value: value, labelText: value);
                }).toList(),
                onChanged: (values) {
                  selectedVariationValues[varItem.id?.toInt()] = values != null && values.isNotEmpty ? values : null;

                  generateVariants(changeState: false);
                },
              );
            },
          ),

        if (selectedVariation.isEmpty) const SizedBox(height: 24),

        // ================= GENERATED VARIANT LIST =================
        if (localVariantStocks.isNotEmpty) ...[
          // const SizedBox(height: 24),
          Row(
            children: [
              Text(
                "${lang.S.of(context).selectVariations} (${localVariantStocks.length})",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: localVariantStocks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stock = localVariantStocks[index];
              // Check if this is a Sub-Variation (contains '-')
              bool isSubVariation = stock.batchNo != null && stock.variantName!.contains('Sub');

              return Container(
                color: isSubVariation ? Colors.grey.shade50 : Colors.transparent, // Light bg for sub items
                child: ListTile(
                  onTap: () {
                    showVariantEditSheet(
                      context: context,
                      stock: localVariantStocks[index],
                      snapShot: widget.snapShot,
                      tax: widget.tax,
                      taxType: widget.taxType,
                      onSave: (updatedStock) {
                        setState(() {
                          localVariantStocks[index] = updatedStock;
                        });
                        widget.onStocksUpdated(localVariantStocks);
                      },
                    );
                  },
                  contentPadding: !isSubVariation ? EdgeInsets.zero : EdgeInsetsDirectional.only(start: 30),
                  // (+) Button only for Parent items
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  leading: !isSubVariation
                      ? IconButton(
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          ),
                          icon: const Icon(Icons.add, color: kTitleColor),
                          tooltip: lang.S.of(context).addSubVariation,
                          onPressed: () => _addSubVariation(index),
                        )
                      : Icon(Icons.subdirectory_arrow_right,
                          color: Colors.grey, size: 18), // Visual indicator for child

                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          stock.variantName ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isSubVariation ? FontWeight.normal : FontWeight.w500,
                            fontSize: isSubVariation ? 13 : 14,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text.rich(TextSpan(
                          text: '${lang.S.of(context).stock}: ',
                          style: _theme.textTheme.bodyMedium?.copyWith(
                            color: kTitleColor,
                          ),
                          children: [
                            TextSpan(
                              text: stock.productStock ?? 'n/a',
                              style: _theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSubVariation ? FontWeight.normal : FontWeight.w500,
                                  fontSize: isSubVariation ? 13 : 14,
                                  color: kPeraColor),
                            )
                          ])),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${lang.S.of(context).batchNo}: ${stock.batchNo ?? 'N/A'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: isSubVariation ? 13 : 14, color: kPeraColor),
                        ),
                      ),
                      Text.rich(TextSpan(
                          text: '${lang.S.of(context).sale}: ',
                          style: _theme.textTheme.bodyMedium?.copyWith(
                            color: kTitleColor,
                          ),
                          children: [
                            TextSpan(
                              text: '$currency${stock.productSalePrice ?? 'n/a'}',
                              style: _theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSubVariation ? FontWeight.normal : FontWeight.w500,
                                fontSize: isSubVariation ? 13 : 14,
                                color: kTitleColor,
                              ),
                            )
                          ])),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 30,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showVariantEditSheet(
                            context: context,
                            stock: localVariantStocks[index],
                            snapShot: widget.snapShot,
                            tax: widget.tax,
                            taxType: widget.taxType,
                            onSave: (updatedStock) {
                              setState(() {
                                localVariantStocks[index] = updatedStock;
                              });
                              widget.onStocksUpdated(localVariantStocks);
                            },
                          );
                        } else if (value == 'delete') {
                          _removeVariation(index);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedPencilEdit02,
                                color: kGreyTextColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                lang.S.of(context).edit,
                                style: _theme.textTheme.titleSmall?.copyWith(
                                  color: kGreyTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Show delete only if sub-variation
                        if (isSubVariation)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedDelete03,
                                  color: kGreyTextColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  lang.S.of(context).edit,
                                  style: _theme.textTheme.titleSmall?.copyWith(
                                    color: kGreyTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        ]
      ],
    );
  }
}

void showVariantEditSheet({
  required BuildContext context,
  required StockDataModel stock,
  required GetProductSettingModel snapShot,
  VatModel? tax,
  required String taxType,
  required Function(StockDataModel updatedStock) onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) =>
        VariantEditSheet(stock: stock, snapShot: snapShot, tax: tax, taxType: taxType, onSave: onSave),
  );
}

class VariantEditSheet extends ConsumerStatefulWidget {
  const VariantEditSheet(
      {super.key,
      required this.stock,
      required this.snapShot,
      required this.tax,
      required this.taxType,
      required this.onSave});
  final StockDataModel stock;
  final GetProductSettingModel snapShot;
  final VatModel? tax;
  final String taxType;
  final Function(StockDataModel) onSave;
  @override
  ConsumerState<VariantEditSheet> createState() => _VariantEditSheetState();
}

class _VariantEditSheetState extends ConsumerState<VariantEditSheet> {
  late TextEditingController productBatchNumberController;
  late TextEditingController productStockController;
  late TextEditingController purchaseExclusivePriceController;
  late TextEditingController purchaseInclusivePriceController;
  late TextEditingController profitMarginController;
  late TextEditingController salePriceController;
  late TextEditingController wholeSalePriceController;
  late TextEditingController dealerPriceController;
  late TextEditingController expireDateController;
  late TextEditingController manufactureDateController;

  String? selectedExpireDate;
  String? selectedManufactureDate;
  String? selectedWarehouseId; // Added variable for Warehouse

  @override
  void initState() {
    super.initState();
    productBatchNumberController = TextEditingController(text: widget.stock.batchNo ?? '');
    productStockController = TextEditingController(text: widget.stock.productStock ?? '');
    purchaseExclusivePriceController = TextEditingController(text: widget.stock.exclusivePrice ?? '');
    purchaseInclusivePriceController = TextEditingController(text: widget.stock.inclusivePrice ?? '');
    profitMarginController = TextEditingController(text: widget.stock.profitPercent ?? '');
    salePriceController = TextEditingController(text: widget.stock.productSalePrice ?? '');
    wholeSalePriceController = TextEditingController(text: widget.stock.productWholeSalePrice ?? '');
    dealerPriceController = TextEditingController(text: widget.stock.productDealerPrice ?? '');
    selectedExpireDate = widget.stock.expireDate;
    selectedManufactureDate = widget.stock.mfgDate;

    // Initialize Warehouse ID
    selectedWarehouseId = widget.stock.warehouseId;

    expireDateController = TextEditingController(
        text: selectedExpireDate != null && selectedExpireDate!.isNotEmpty
            ? DateFormat.yMd().format(DateTime.parse(selectedExpireDate!))
            : '');
    manufactureDateController = TextEditingController(
        text: selectedManufactureDate != null && selectedManufactureDate!.isNotEmpty
            ? DateFormat.yMd().format(DateTime.parse(selectedManufactureDate!))
            : '');
  }

  @override
  void dispose() {
    productBatchNumberController.dispose();
    productStockController.dispose();
    purchaseExclusivePriceController.dispose();
    purchaseInclusivePriceController.dispose();
    profitMarginController.dispose();
    salePriceController.dispose();
    wholeSalePriceController.dispose();
    dealerPriceController.dispose();
    expireDateController.dispose();
    manufactureDateController.dispose();
    super.dispose();
  }

  void calculatePurchaseAndMrp({String? from}) {
    num taxRate = widget.tax?.rate ?? 0;
    num purchaseExc = num.tryParse(purchaseExclusivePriceController.text) ?? 0;
    num purchaseInc = num.tryParse(purchaseInclusivePriceController.text) ?? 0;
    num profitMargin = num.tryParse(profitMarginController.text) ?? 0;
    num salePrice = num.tryParse(salePriceController.text) ?? 0;

    if (from == 'purchase_inc') {
      purchaseExc = (taxRate != 0) ? purchaseInc / (1 + taxRate / 100) : purchaseInc;
      purchaseExclusivePriceController.text = purchaseExc.toStringAsFixed(2);
    } else {
      purchaseInc = purchaseExc + (purchaseExc * taxRate / 100);
      purchaseInclusivePriceController.text = purchaseInc.toStringAsFixed(2);
    }
    purchaseExc = num.tryParse(purchaseExclusivePriceController.text) ?? 0;
    purchaseInc = num.tryParse(purchaseInclusivePriceController.text) ?? 0;
    num basePrice = widget.taxType.toLowerCase() == 'exclusive' ? purchaseExc : purchaseInc;

    if (from == 'mrp') {
      salePrice = num.tryParse(salePriceController.text) ?? 0;
      if (basePrice > 0) {
        profitMargin = ((salePrice - basePrice) / basePrice) * 100;
        profitMarginController.text = profitMargin.toStringAsFixed(2);
      }
    } else {
      if (basePrice > 0) {
        salePrice = basePrice + (basePrice * profitMargin / 100);
        salePriceController.text = salePrice.toStringAsFixed(2);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(ref);
    final theme = Theme.of(context);
    final modules = widget.snapShot.data?.modules;

    // 1. Fetch Warehouse List from Provider
    final warehouseData = ref.watch(fetchWarehouseListProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration:
            const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: Text('${lang.S.of(context).edit} ${widget.stock.variantName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey))
              ])),
          const Divider(height: 1, color: kBorderColor),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // 2. Display Warehouse Dropdown
                warehouseData.when(
                    data: (data) => DropdownButtonFormField<String>(
                        value: selectedWarehouseId,
                        decoration: InputDecoration(
                            labelText: lang.S.of(context).warehouse,
                            hintText: lang.S.of(context).selectWarehouse,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        items: data.data
                            ?.map((WarehouseData w) =>
                                DropdownMenuItem<String>(value: w.id.toString(), child: Text(w.name ?? '')))
                            .toList(),
                        onChanged: (v) => setState(() => selectedWarehouseId = v)),
                    error: (e, s) => const Text('Failed to load warehouse'),
                    loading: () => const Center(child: LinearProgressIndicator())),
                const SizedBox(height: 16),

                if (modules?.showBatchNo == '1' || modules?.showProductStock == '1') ...[
                  Row(children: [
                    if (modules?.showBatchNo == '1')
                      Expanded(
                          child: _buildField(
                              controller: productBatchNumberController,
                              label: lang.S.of(context).batchNo,
                              hint: "Ex: B-001")),
                    if (modules?.showBatchNo == '1' && modules?.showProductStock == '1') const SizedBox(width: 12),
                    if (modules?.showProductStock == '1')
                      Expanded(
                          child: _buildField(
                              controller: productStockController,
                              label: lang.S.of(context).stock,
                              isNumber: true,
                              hint: "Ex: 50"))
                  ]),
                  const SizedBox(height: 16)
                ],
                if ((modules?.showExclusivePrice == '1' || modules?.showInclusivePrice == '1') &&
                    permissionService.hasPermission(Permit.productsPriceView.value)) ...[
                  Row(children: [
                    if (modules?.showExclusivePrice == '1')
                      Expanded(
                          child: _buildField(
                              controller: purchaseExclusivePriceController,
                              label: lang.S.of(context).purchaseEx,
                              isNumber: true,
                              hint: "Ex: 100.00",
                              onChanged: (v) => calculatePurchaseAndMrp())),
                    if (modules?.showExclusivePrice == '1' && modules?.showInclusivePrice == '1')
                      const SizedBox(width: 12),
                    if (modules?.showInclusivePrice == '1')
                      Expanded(
                          child: _buildField(
                              controller: purchaseInclusivePriceController,
                              label: lang.S.of(context).purchaseIn,
                              isNumber: true,
                              hint: "Ex: 115.00",
                              onChanged: (v) => calculatePurchaseAndMrp(from: "purchase_inc")))
                  ]),
                  const SizedBox(height: 16)
                ],
                if (modules?.showProfitPercent == '1' || modules?.showProductSalePrice == '1') ...[
                  Row(children: [
                    if (modules?.showProfitPercent == '1' &&
                        permissionService.hasPermission(Permit.productsPriceView.value))
                      Expanded(
                          child: _buildField(
                              controller: profitMarginController,
                              label: lang.S.of(context).profitMargin,
                              isNumber: true,
                              hint: "Ex: 20%",
                              onChanged: (v) => calculatePurchaseAndMrp())),
                    if (modules?.showProfitPercent == '1' &&
                        modules?.showProductSalePrice == '1' &&
                        permissionService.hasPermission(Permit.productsPriceView.value))
                      const SizedBox(width: 12),
                    if (modules?.showProductSalePrice == '1')
                      Expanded(
                          child: _buildField(
                              controller: salePriceController,
                              label: lang.S.of(context).mrp,
                              isNumber: true,
                              hint: "Ex: 150.00",
                              onChanged: (v) => calculatePurchaseAndMrp(from: 'mrp')))
                  ]),
                  const SizedBox(height: 16)
                ],
                if (modules?.showProductWholesalePrice == '1' || modules?.showProductDealerPrice == '1') ...[
                  Row(children: [
                    if (modules?.showProductWholesalePrice == '1')
                      Expanded(
                          child: _buildField(
                              controller: wholeSalePriceController,
                              label: lang.S.of(context).wholeSalePrice,
                              isNumber: true,
                              hint: "Ex: 130.00")),
                    if (modules?.showProductWholesalePrice == '1' && modules?.showProductDealerPrice == '1')
                      const SizedBox(width: 12),
                    if (modules?.showProductDealerPrice == '1')
                      Expanded(
                          child: _buildField(
                              controller: dealerPriceController,
                              label: lang.S.of(context).dealerPrice,
                              isNumber: true,
                              hint: "Ex: 120.00"))
                  ]),
                  const SizedBox(height: 16)
                ],
                if (modules?.showMfgDate == '1' || modules?.showExpireDate == '1') ...[
                  Row(children: [
                    if (modules?.showMfgDate == '1')
                      Expanded(
                          child: _buildDateField(
                              controller: manufactureDateController,
                              label: lang.S.of(context).manufactureDate,
                              isExpire: false,
                              hint: lang.S.of(context).selectDate)),
                    if (modules?.showMfgDate == '1' && modules?.showExpireDate == '1') const SizedBox(width: 12),
                    if (modules?.showExpireDate == '1')
                      Expanded(
                          child: _buildDateField(
                        controller: expireDateController,
                        label: lang.S.of(context).expDate,
                        isExpire: true,
                        hint: lang.S.of(context).selectDate,
                      ))
                  ]),
                  const SizedBox(height: 24)
                ],
                SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                        onPressed: () {
                          // 3. Set the selected warehouse ID to the stock object
                          widget.stock.warehouseId = selectedWarehouseId;

                          widget.stock.batchNo = productBatchNumberController.text;
                          widget.stock.productStock = productStockController.text;
                          widget.stock.exclusivePrice = purchaseExclusivePriceController.text;
                          widget.stock.inclusivePrice = purchaseInclusivePriceController.text;
                          widget.stock.profitPercent = profitMarginController.text;
                          widget.stock.productSalePrice = salePriceController.text;
                          widget.stock.productWholeSalePrice = wholeSalePriceController.text;
                          widget.stock.productDealerPrice = dealerPriceController.text;
                          widget.stock.expireDate = selectedExpireDate;
                          widget.stock.mfgDate = selectedManufactureDate;
                          widget.onSave(widget.stock);
                          Navigator.pop(context);
                        },
                        child: Text(lang.S.of(context).saveVariant))),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String label,
      String? hint,
      bool isNumber = false,
      Function(String)? onChanged}) {
    return TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))] : [],
        onChanged: onChanged,
        decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)));
  }

  Widget _buildDateField(
      {required TextEditingController controller, required String label, String? hint, required bool isExpire}) {
    return TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: const Icon(Icons.calendar_today, size: 18)),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
              context: context, initialDate: DateTime.now(), firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
          if (picked != null) {
            setState(() {
              controller.text = DateFormat.yMd().format(picked);
              if (isExpire) {
                selectedExpireDate = picked.toString();
              } else {
                selectedManufactureDate = picked.toString();
              }
            });
          }
        });
  }
}

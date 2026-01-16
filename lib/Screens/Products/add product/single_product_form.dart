import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Screens/Products/product_setting/model/get_product_setting_model.dart';
import 'package:mobile_pos/Screens/warehouse/warehouse_model/warehouse_list_model.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../constant.dart';
import '../../../service/check_user_role_permission_provider.dart';
import '../../warehouse/warehouse_provider/warehouse_provider.dart';

class SingleProductForm extends ConsumerWidget {
  const SingleProductForm({
    super.key,
    required this.snapShot,
    required this.batchController,
    required this.stockController,
    required this.purchaseExController,
    required this.purchaseIncController,
    required this.profitController,
    required this.saleController,
    required this.wholesaleController,
    required this.dealerController,
    required this.mfgDateController,
    required this.expDateController,
    this.selectedWarehouse,
    required this.onWarehouseChanged,
    required this.onPriceChanged,
    required this.onMfgDateSelected,
    required this.onExpDateSelected,
  });

  final GetProductSettingModel snapShot;

  // Controllers passed from Parent
  final TextEditingController batchController;
  final TextEditingController stockController;
  final TextEditingController purchaseExController;
  final TextEditingController purchaseIncController;
  final TextEditingController profitController;
  final TextEditingController saleController;
  final TextEditingController wholesaleController;
  final TextEditingController dealerController;
  final TextEditingController mfgDateController;
  final TextEditingController expDateController;

  // State variables passed from Parent
  final WarehouseData? selectedWarehouse;

  // Callbacks to update Parent State
  final Function(WarehouseData?) onWarehouseChanged;
  final Function(String from) onPriceChanged; // To trigger calculation
  final Function(String date) onMfgDateSelected;
  final Function(String date) onExpDateSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = PermissionService(ref);
    final warehouseData = ref.watch(fetchWarehouseListProvider);
    final modules = snapShot.data?.modules;
    final _lang = lang.S.of(context);

    return Column(
      children: [
        ///-------------Batch No & Warehouse----------------------------------
        if (modules?.showBatchNo == '1' || modules?.showWarehouse == '1') ...[
          const SizedBox(height: 24),
          Row(
            children: [
              if (modules?.showBatchNo == '1')
                Expanded(
                  child: TextFormField(
                    controller: batchController,
                    decoration: InputDecoration(
                      labelText: _lang.batchNo,
                      hintText: _lang.enterBatchNo,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              if (modules?.showBatchNo == '1' && modules?.showWarehouse == '1') const SizedBox(width: 14),
              if (modules?.showWarehouse == '1')
                Expanded(
                  child: warehouseData.when(
                    data: (dataList) {
                      return Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          DropdownButtonFormField<WarehouseData>(
                            hint: Text(_lang.selectWarehouse),
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: _lang.warehouse,
                            ),
                            initialValue: selectedWarehouse,
                            icon: selectedWarehouse != null
                                ? IconButton(
                                    style: IconButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      onWarehouseChanged.call(null);
                                    },
                                  )
                                : const Icon(Icons.keyboard_arrow_down_outlined),
                            items: dataList.data
                                ?.map(
                                  (rack) => DropdownMenuItem<WarehouseData>(
                                    value: rack,
                                    child: Text(
                                      rack.name ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: onWarehouseChanged,
                          ),
                        ],
                      );
                    },
                    error: (e, st) => const Text('Warehouse Load Error'),
                    loading: () => const Center(child: CircularProgressIndicator()),
                  ),
                  // child: warehouseData.when(
                  //   data: (dataList) {
                  //     return DropdownButtonFormField<WarehouseData>(
                  //       hint: const Text('Select Warehouse'),
                  //       isExpanded: true,
                  //       decoration: const InputDecoration(labelText: 'Warehouse', border: OutlineInputBorder()),
                  //       value: selectedWarehouse,
                  //       icon: const Icon(Icons.keyboard_arrow_down_outlined),
                  //       items: dataList.data
                  //           ?.map(
                  //             (rack) => DropdownMenuItem<WarehouseData>(
                  //               value: rack,
                  //               child: Text(rack.name ?? '', style: const TextStyle(fontWeight: FontWeight.normal)),
                  //             ),
                  //           )
                  //           .toList(),
                  //       onChanged: onWarehouseChanged,
                  //     );
                  //   },
                  //   error: (e, st) => const Text('Rack Load Error'),
                  //   loading: () => const Center(child: CircularProgressIndicator()),
                  // ),
                ),
            ],
          ),
        ],

        if (modules?.showProductStock == '1') const SizedBox(height: 24),

        ///-------------Stock--------------------------------------
        if (modules?.showProductStock == '1')
          TextFormField(
            controller: stockController,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelText: lang.S.of(context).stock,
              hintText: lang.S.of(context).enterStock,
              border: const OutlineInputBorder(),
            ),
          ),

        ///_________Purchase Price (Exclusive & Inclusive)____________________
        if ((modules?.showExclusivePrice == '1' || modules?.showInclusivePrice == '1') &&
            permissionService.hasPermission(Permit.productsPriceView.value)) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              if (modules?.showExclusivePrice == '1')
                Expanded(
                  child: TextFormField(
                    controller: purchaseExController,
                    onChanged: (value) => onPriceChanged('purchase_ex'),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).purchaseEx,
                      hintText: lang.S.of(context).enterPurchasePrice,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              if (modules?.showExclusivePrice == '1' && modules?.showInclusivePrice == '1') const SizedBox(width: 14),
              if (modules?.showInclusivePrice == '1')
                Expanded(
                  child: TextFormField(
                    controller: purchaseIncController,
                    onChanged: (value) => onPriceChanged('purchase_inc'),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).purchaseIn,
                      hintText: lang.S.of(context).enterSaltingPrice,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ],

        ///_________Profit Margin & MRP_____________________
        if (modules?.showProfitPercent == '1' || modules?.showProductSalePrice == '1') ...[
          const SizedBox(height: 24),
          Row(
            children: [
              if (modules?.showProfitPercent == '1' &&
                  (permissionService.hasPermission(Permit.productsPriceView.value)))
                Expanded(
                  child: TextFormField(
                    controller: profitController,
                    onChanged: (value) => onPriceChanged('profit_margin'),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).profitMargin,
                      hintText: lang.S.of(context).enterPurchasePrice,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              if (modules?.showProfitPercent == '1' &&
                  modules?.showProductSalePrice == '1' &&
                  permissionService.hasPermission(Permit.productsPriceView.value))
                const SizedBox(width: 14),
              if (modules?.showProductSalePrice == '1')
                Expanded(
                  child: TextFormField(
                    controller: saleController,
                    onChanged: (value) => onPriceChanged('mrp'),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).mrp,
                      hintText: lang.S.of(context).enterSaltingPrice,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ],

        ///_______Wholesale & Dealer Price_________________
        if (modules?.showProductWholesalePrice == '1' || modules?.showProductDealerPrice == '1') ...[
          const SizedBox(height: 24),
          Row(
            children: [
              if (modules?.showProductWholesalePrice == '1')
                Expanded(
                  child: TextFormField(
                    controller: wholesaleController,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).wholeSalePrice,
                      hintText: lang.S.of(context).enterWholesalePrice,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              if (modules?.showProductWholesalePrice == '1' && modules?.showProductDealerPrice == '1')
                const SizedBox(width: 14),
              if (modules?.showProductDealerPrice == '1')
                Expanded(
                  child: TextFormField(
                    controller: dealerController,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).dealerPrice,
                      hintText: lang.S.of(context).enterDealerPrice,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ],

        ///_______Dates_________________
        if ((modules?.showMfgDate == '1') || (modules?.showExpireDate == '1')) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              if (modules?.showMfgDate == '1')
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: mfgDateController,
                    decoration: InputDecoration(
                      labelText: lang.S.of(context).manuDate,
                      hintText: lang.S.of(context).selectDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2015, 8),
                            lastDate: DateTime(2101),
                            context: context,
                          );
                          if (picked != null) {
                            onMfgDateSelected(picked.toString());
                          }
                        },
                        icon: const Icon(IconlyLight.calendar, size: 22),
                      ),
                    ),
                  ),
                ),
              if (modules?.showMfgDate == '1' && modules?.showExpireDate == '1') const SizedBox(width: 14),
              if (modules?.showExpireDate == '1')
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: expDateController,
                    decoration: InputDecoration(
                      labelText: lang.S.of(context).expDate,
                      hintText: lang.S.of(context).selectDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2015, 8),
                            lastDate: DateTime(2101),
                            context: context,
                          );
                          if (picked != null) {
                            onExpDateSelected(picked.toString());
                          }
                        },
                        icon: const Icon(IconlyLight.calendar, size: 22),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/GlobalComponents/returned_tag_widget.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:mobile_pos/generated/l10n.dart' as l;

import '../PDF Invoice/sales_invoice_pdf.dart';
import '../Provider/profile_provider.dart';
import '../Screens/Loss_Profit/single_loss_profit_screen.dart';
import '../Screens/Sales/add_sales.dart';
import '../Screens/Sales/provider/sales_cart_provider.dart';
import '../Screens/invoice return/invoice_return_screen.dart';
import '../Screens/invoice_details/sales_invoice_details_screen.dart';
import '../constant.dart';
import '../core/theme/_app_colors.dart';
import '../currency.dart';
import '../generated/l10n.dart' as lang;
import '../model/business_info_model.dart' as bInfo;
import '../service/check_actions_when_no_branch.dart';
import '../thermal priting invoices/provider/print_thermal_invoice_provider.dart';

Widget salesTransactionWidget({
  required BuildContext context,
  required SalesTransactionModel sale,
  required bInfo.BusinessInformationModel businessInfo,
  required WidgetRef ref,
  bool? showProductQTY,
  required bool advancePermission,
  bool? fromLossProfit,
  num? returnAmount,
  bool? isFromSaleList,
}) {
  final theme = Theme.of(context);
  final _lang = l.S.of(context);
  final printerData = ref.watch(thermalPrinterProvider);
  return Column(
    children: [
      InkWell(
        onTap: () {
          if (fromLossProfit ?? false) {
            SingleLossProfitScreen(
              transactionModel: sale,
            ).launch(context);
          } else {
            SalesInvoiceDetails(
              saleTransaction: sale,
              businessInfo: businessInfo,
            ).launch(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      (showProductQTY ?? false)
                          ? "${lang.S.of(context).totalProduct} : ${sale.salesDetails?.length.toString()}"
                          : sale.party?.name ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#${sale.invoiceNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ///_____Payment_Sttus________________________________________
                      getPaymentStatusBadge(
                          context: context, dueAmount: sale.dueAmount!, totalAmount: sale.totalAmount!),

                      ///________Return_tag_________________________________________
                      ReturnedTagWidget(show: sale.salesReturns?.isNotEmpty ?? false),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      DateFormat('dd MMM, yyyy').format(DateTime.parse(sale.saleDate ?? '')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: kPeragrapColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lang.S.of(context).total} : $currency${formatPointNumber(sale.totalAmount ?? 0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: kPeraColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (sale.dueAmount!.toInt() != 0)
                    Text(
                      '${lang.S.of(context).paid} : $currency${formatPointNumber(
                        (sale.totalAmount!.toDouble() - sale.dueAmount!.toDouble()),
                      )}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: kPeraColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (fromLossProfit ?? false) ...{
                    Flexible(
                      child: Text(
                        '${lang.S.of(context).profit} : $currency ${formatPointNumber(sale.detailsSumLossProfit ?? 0)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ).visible(!sale.detailsSumLossProfit!.isNegative),
                    ),
                    Flexible(
                      child: Text(
                        '${lang.S.of(context).loss}: $currency ${formatPointNumber(sale.detailsSumLossProfit!.abs())}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ).visible(sale.detailsSumLossProfit!.isNegative),
                    ),
                  } else ...{
                    if (sale.dueAmount!.toInt() == 0)
                      Flexible(
                        child: Text(
                          (returnAmount != null)
                              ? '${_lang.returnedAmount}: $currency${formatPointNumber(returnAmount)}'
                              : '${lang.S.of(context).paid} : $currency${formatPointNumber((sale.totalAmount!.toDouble() - sale.dueAmount!.toDouble()))}',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                        ),
                      ),
                    if (sale.dueAmount!.toInt() != 0)
                      Flexible(
                        child: Text(
                          (returnAmount != null)
                              ? '${_lang.returnedAmount}: $currency${formatPointNumber(returnAmount)}'
                              : '${lang.S.of(context).due}: $currency${formatPointNumber(sale.dueAmount ?? 0)}',
                          maxLines: 2,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  },
                  Row(
                    children: [
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            onPressed: () =>
                                SalesInvoicePdf.generateSaleDocument(sale, businessInfo, context, showPreview: true),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedPdf02,
                              size: 22,
                              color: kPeraColor,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            onPressed: () async {
                              // PrintSalesTransactionModel model = PrintSalesTransactionModel(transitionModel: sale, personalInformationModel: businessInfo);
                              // await printerData.printSalesThermalInvoiceNow(
                              //   transaction: model,
                              //   productList: model.transitionModel!.salesDetails,
                              //   context: context,
                              // );
                              SalesInvoiceDetails(
                                saleTransaction: sale,
                                businessInfo: businessInfo,
                              ).launch(context);
                            },
                            icon: const Icon(
                              FeatherIcons.printer,
                              color: kPeraColor,
                              size: 22,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            onPressed: () => SalesInvoiceExcel.generateSaleDocument(sale, businessInfo, context),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedXls02,
                              size: 22,
                              color: kPeraColor,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            onPressed: () =>
                                SalesInvoicePdf.generateSaleDocument(sale, businessInfo, context, download: true),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedDownload01,
                              size: 22,
                              color: kPeraColor,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            onPressed: () =>
                                SalesInvoicePdf.generateSaleDocument(sale, businessInfo, context, share: true),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedShare08,
                              size: 22,
                              color: kPeraColor,
                            ),
                          ),
                        ],
                      ),

                      ///________Sales_return_____________________________
                      if (isFromSaleList == true)
                        if (advancePermission)
                          PopupMenuButton(
                            offset: const Offset(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: EdgeInsets.zero,
                            itemBuilder: (BuildContext bc) => [
                              ///________Sale Return___________________________________
                              PopupMenuItem(
                                child: GestureDetector(
                                  onTap: () async {
                                    bool result = await checkActionWhenNoBranch(ref: ref, context: context);
                                    if (!result) {
                                      return;
                                    }
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InvoiceReturnScreen(saleTransactionModel: sale),
                                      ),
                                    );
                                    Navigator.pop(bc);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.keyboard_return_outlined,
                                        color: kGreyTextColor,
                                      ),
                                      SizedBox(width: 10.0),
                                      Text(
                                        _lang.saleReturn,
                                        style: TextStyle(color: kGreyTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              PopupMenuItem(
                                onTap: () async {
                                  ref.refresh(cartNotifier);
                                  AddSalesScreen(
                                    transitionModel: sale,
                                    customerModel: null,
                                  ).launch(context);
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      FeatherIcons.edit,
                                      color: kGreyTextColor,
                                    ),
                                    SizedBox(width: 10.0),
                                    Text(
                                      _lang.saleEdit,
                                      style: TextStyle(color: kGreyTextColor),
                                    ),
                                  ],
                                ),
                                // child:
                                //
                                //     ///_________Sales_edit___________________________
                                //     Visibility(
                                //   visible: !(sale.salesReturns?.isNotEmpty ?? false),
                                //   child: const Icon(
                                //     FeatherIcons.edit,
                                //     color: Colors.grey,
                                //   ),
                                // ),
                              ),
                            ],
                            onSelected: (value) {
                              Navigator.pushNamed(context, '$value');
                            },
                            child: const Icon(
                              FeatherIcons.moreVertical,
                              color: kPeraColor,
                            ),
                          ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      Divider(height: 1, color: kLineColor),
    ],
  );
}

Widget getPaymentStatusBadge({required num dueAmount, required num totalAmount, required BuildContext context}) {
  String status;
  Color textColor;
  Color bgColor;

  if (dueAmount <= 0) {
    status = lang.S.of(context).paid;
    textColor = const Color(0xff0dbf7d);
    bgColor = const Color(0xff0dbf7d).withOpacity(0.1);
  } else if (dueAmount >= totalAmount) {
    status = lang.S.of(context).unPaid;
    textColor = const Color(0xFFED1A3B);
    bgColor = const Color(0xFFED1A3B).withOpacity(0.1);
  } else {
    status = lang.S.of(context).partialPaid;
    textColor = const Color(0xFFFFA500);
    bgColor = const Color(0xFFFFA500).withOpacity(0.1);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    ),
    child: Text(
      status,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
    ),
  );
}

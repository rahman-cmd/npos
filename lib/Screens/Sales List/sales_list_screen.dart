import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/add_to_cart.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../Provider/profile_provider.dart';
import '../../../constant.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../GlobalComponents/returned_tag_widget.dart';
import '../../PDF Invoice/generate_pdf.dart';
import '../../currency.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../Home/home.dart';
import '../Sales/add_sales.dart';
import '../invoice_details/sales_invoice_details_screen.dart';
import '../invoice return/invoice_return_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SalesListScreenState createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.refresh(salesTransactionProvider);
    ref.refresh(businessInfoProvider);
    ref.refresh(thermalPrinterProvider);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await const Home().launch(context, isNewTask: true);
      },
      child: GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(
              lang.S.of(context).saleList,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Consumer(builder: (context, ref, __) {
            final providerData = ref.watch(salesTransactionProvider);
            final profile = ref.watch(businessInfoProvider);
            final printerData = ref.watch(thermalPrinterProvider);
            final businessSettingData = ref.watch(businessSettingProvider);
            return RefreshIndicator.adaptive(
              onRefresh: () => refreshData(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: providerData.when(data: (transaction) {
                  return transaction.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transaction.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                SalesInvoiceDetails(
                                  saleTransaction: transaction[index],
                                  businessInfo: profile.value!,
                                ).launch(context);
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    width: context.width(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              transaction[index].party?.name ?? '',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            Text('#${transaction[index].invoiceNumber}'),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                      color:
                                                          transaction[index].dueAmount! <= 0 ? const Color(0xff0dbf7d).withOpacity(0.1) : const Color(0xFFED1A3B).withOpacity(0.1),
                                                      borderRadius: const BorderRadius.all(Radius.circular(10))),
                                                  child: Text(
                                                    transaction[index].dueAmount! <= 0 ? lang.S.of(context).paid : lang.S.of(context).unPaid,
                                                    style: TextStyle(color: transaction[index].dueAmount! <= 0 ? const Color(0xff0dbf7d) : const Color(0xFFED1A3B)),
                                                  ),
                                                ),

                                                ///________Return_tag_________________________________________
                                                ReturnedTagWidget(show: transaction[index].salesReturns?.isNotEmpty ?? false),
                                              ],
                                            ),
                                            Text(
                                              DateFormat.yMMMd().format(DateTime.parse(transaction[index].saleDate ?? '')),
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          ' ${lang.S.of(context).total} : $currency ${transaction[index].totalAmount.toString()}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${lang.S.of(context).paid} : $currency ${transaction[index].totalAmount!.toDouble() - transaction[index].dueAmount!.toDouble()}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${lang.S.of(context).due}: $currency ${transaction[index].dueAmount.toString()}',
                                              style: const TextStyle(fontSize: 16),
                                            ).visible(transaction[index].dueAmount!.toInt() != 0),
                                            profile.when(data: (data) {
                                              return Row(
                                                children: [
                                                  IconButton(
                                                      padding: EdgeInsets.zero,
                                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                      onPressed: () async {
                                                        PrintTransactionModel model = PrintTransactionModel(transitionModel: transaction[index], personalInformationModel: data);
                                                        await printerData.printSalesThermalInvoiceNow(
                                                          transaction: model,
                                                          productList: model.transitionModel!.salesDetails,
                                                          context: context,
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        FeatherIcons.printer,
                                                        color: Colors.grey,
                                                      )),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  businessSettingData.when(data: (business) {
                                                    return IconButton(
                                                        padding: EdgeInsets.zero,
                                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                        onPressed: () => GeneratePdf().generateSaleDocument(transaction[index], data, context, business),
                                                        icon: const Icon(
                                                          Icons.picture_as_pdf,
                                                          color: Colors.grey,
                                                        ));
                                                  }, error: (e, stack) {
                                                    return Text(e.toString());
                                                  }, loading: () {
                                                    return const Center(
                                                      child: CircularProgressIndicator(),
                                                    );
                                                  }),
                                                  const SizedBox(width: 10),

                                                  ///_________Sales_edit___________________________
                                                  Visibility(
                                                    visible: !(transaction[index].salesReturns?.isNotEmpty ?? false),
                                                    child: IconButton(
                                                        padding: EdgeInsets.zero,
                                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                        onPressed: () {
                                                          ref.refresh(cartNotifier);
                                                          AddSalesScreen(
                                                            transitionModel: transaction[index],
                                                            customerModel: null,
                                                          ).launch(context);
                                                        },
                                                        icon: const Icon(
                                                          FeatherIcons.edit,
                                                          color: Colors.grey,
                                                        )),
                                                  ),

                                                  PopupMenuButton(
                                                    offset: const Offset(0, 30),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4.0),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    itemBuilder: (BuildContext bc) => [
                                                      ///________Sale List Delete_______________________________
                                                      // PopupMenuItem(
                                                      //   child: GestureDetector(
                                                      //     onTap: () async {
                                                      //       bool? result = await invoiceDeleteAlert(context: context, type: 'Sales Invoice');
                                                      //       if (result != null && result) {}
                                                      //     },
                                                      //     child: const Row(
                                                      //       children: [
                                                      //         Icon(
                                                      //           Icons.delete,
                                                      //           color: kGreyTextColor,
                                                      //         ),
                                                      //         SizedBox(
                                                      //           width: 10.0,
                                                      //         ),
                                                      //         Text(
                                                      //           'Delete',
                                                      //           style: TextStyle(color: kGreyTextColor),
                                                      //         ),
                                                      //       ],
                                                      //     ),
                                                      //   ),
                                                      // ),

                                                      ///________Sale Return___________________________________
                                                      PopupMenuItem(
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => InvoiceReturnScreen(saleTransactionModel: transaction[index]),
                                                              ),
                                                            );
                                                            Navigator.pop(bc);
                                                          },
                                                          child: const Row(
                                                            children: [
                                                              Icon(
                                                                Icons.keyboard_return_outlined,
                                                                color: kGreyTextColor,
                                                              ),
                                                              SizedBox(width: 10.0),
                                                              Text(
                                                                'Sale return',
                                                                style: TextStyle(color: kGreyTextColor),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    onSelected: (value) {
                                                      Navigator.pushNamed(context, '$value');
                                                    },
                                                    child: const Icon(
                                                      FeatherIcons.moreVertical,
                                                      color: kGreyTextColor,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }, error: (e, stack) {
                                              return Text(e.toString());
                                            }, loading: () {
                                              // return const Text('Loading');
                                              return Text(lang.S.of(context).loading);
                                            }),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 0.5,
                                    width: context.width(),
                                    color: Colors.grey,
                                  )
                                ],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            lang.S.of(context).addSale,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20.0),
                          ),
                        );
                }, error: (e, stack) {
                  return Text(e.toString());
                }, loading: () {
                  return const Center(child: CircularProgressIndicator());
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

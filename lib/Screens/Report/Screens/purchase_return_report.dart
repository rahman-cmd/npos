//ignore_for_file: file_names, unused_element, unused_local_variable
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../GlobalComponents/glonal_popup.dart';
import '../../../PDF Invoice/generate_pdf.dart';
import '../../../Provider/profile_provider.dart';
import '../../../constant.dart';
import '../../../currency.dart';
import '../../../thermal priting invoices/model/print_transaction_model.dart';
import '../../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../../invoice_details/purchase_invoice_details.dart';

class PurchaseReturnReportScreen extends StatefulWidget {
  const PurchaseReturnReportScreen({super.key});

  @override
  PurchaseReportState createState() => PurchaseReportState();
}

class PurchaseReportState extends State<PurchaseReturnReportScreen> {
  TextEditingController fromDateTextEditingController = TextEditingController(text: DateFormat.yMMMd().format(DateTime(DateTime.now().year, DateTime.now().month, 1)));
  TextEditingController toDateTextEditingController = TextEditingController(text: DateFormat.yMMMd().format(DateTime.now()));
  DateTime fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime toDate = DateTime.now();

  List<String> timeLimit = ['ToDay', 'This Week', 'This Month', 'This Year', 'All Time'];
  String? dropdownValue = 'This Month';
  Map<String, String> getTranslateTime(BuildContext context) {
    return {
      'ToDay': lang.S.of(context).today,
      'This Week': lang.S.of(context).thisWeek,
      'This Month': lang.S.of(context).thisMonth,
      'This Year': lang.S.of(context).thisYear,
      "All Time": lang.S.of(context).allTime,
      // "Custom": lang.S.of(context).custom,
    };
  }

  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.refresh(purchaseReturnTransactionProvider);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  void changeDate({required DateTime from}) {
    setState(() {
      fromDate = from;
      fromDateTextEditingController = TextEditingController(text: DateFormat.yMMMd().format(from));

      toDate = DateTime.now();
      toDateTextEditingController = TextEditingController(text: DateFormat.yMMMd().format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final translateTime = getTranslateTime(context);
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          title: Text(
            lang.S.of(context).purchaseReturnReport,
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
          final purchaseData = ref.watch(purchaseReturnTransactionProvider);
          final printerData = ref.watch(thermalPrinterProvider);
          final personalData = ref.watch(businessInfoProvider);
          final profile = ref.watch(businessInfoProvider);
          final businessData = ref.watch(businessSettingProvider);

          return RefreshIndicator(
            onRefresh: () => refreshData(ref),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0, left: 20.0, top: 20, bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            textFieldType: TextFieldType.NAME,
                            readOnly: true,
                            controller: fromDateTextEditingController,
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText: lang.S.of(context).fromDate,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2015, 8),
                                    lastDate: DateTime(2101),
                                    context: context,
                                  );
                                  setState(() {
                                    fromDateTextEditingController.text = DateFormat.yMMMd().format(picked ?? DateTime.now());
                                    fromDate = picked!;
                                    dropdownValue = 'Custom';
                                  });
                                },
                                icon: const Icon(FeatherIcons.calendar),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            textFieldType: TextFieldType.NAME,
                            readOnly: true,
                            controller: toDateTextEditingController,
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText: lang.S.of(context).toDate,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    initialDate: toDate,
                                    firstDate: DateTime(2015, 8),
                                    lastDate: DateTime(2101),
                                    context: context,
                                  );

                                  setState(() {
                                    toDateTextEditingController.text = DateFormat.yMMMd().format(picked ?? DateTime.now());
                                    picked!.isToday ? toDate = DateTime.now() : toDate = picked;

                                    dropdownValue = 'Custom';
                                  });
                                },
                                icon: const Icon(FeatherIcons.calendar),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  purchaseData.when(data: (transaction) {
                    double totalPurchaseReturn = 0;
                    for (var element in transaction) {
                      if ((fromDate.isBefore(DateTime.parse(element.purchaseDate ?? '')) || DateTime.parse(element.purchaseDate ?? '').isAtSameMomentAs(fromDate)) &&
                          (toDate.isAfter(DateTime.parse(element.purchaseDate ?? '')) || DateTime.parse(element.purchaseDate ?? '').isAtSameMomentAs(toDate))) {
                        for (var element in element.purchaseReturns!) {
                          for (var d in element.purchaseReturnDetails!) {
                            totalPurchaseReturn += (d.returnAmount ?? 0);
                          }
                        }
                      }
                    }
                    return transaction.isNotEmpty
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: kMainColor.withOpacity(0.1),
                                      border: Border.all(width: 1, color: kMainColor),
                                      borderRadius: const BorderRadius.all(Radius.circular(15))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "$currency ${totalPurchaseReturn.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Total Return',
                                            //'Total Purchase',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 1,
                                        height: 60,
                                        color: kMainColor,
                                      ),
                                      Container(
                                        height: 40,
                                        width: 150,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(border: Border.all(color: kMainColor, width: 1), borderRadius: const BorderRadius.all(Radius.circular(8))),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton(
                                            underline: null,
                                            // underline: const Divider(color: Colors.black),
                                            value: dropdownValue,
                                            icon: const Icon(Icons.keyboard_arrow_down),
                                            items: timeLimit.map((String items) {
                                              return DropdownMenuItem(
                                                value: items,
                                                child: Text(translateTime[items] ?? items),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                dropdownValue = newValue.toString();

                                                switch (newValue) {
                                                  case 'ToDay':
                                                    changeDate(from: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
                                                    break;
                                                  case 'This Week':
                                                    changeDate(from: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().weekday));
                                                    break;
                                                  case 'This Month':
                                                    changeDate(from: DateTime(DateTime.now().year, DateTime.now().month, 1));
                                                    break;
                                                  case 'This Year':
                                                    changeDate(from: DateTime(DateTime.now().year, 1, 1));
                                                    break;
                                                  case 'All Time':
                                                    changeDate(from: DateTime(2020, 1, 1));
                                                    break;
                                                  // case 'Custom':
                                                  //   _setCustomDateRange(context);
                                                  //   break;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: transaction.length,
                                itemBuilder: (context, index) {
                                  num returndAmount = 0;
                                  for (var element in transaction[index].purchaseReturns!) {
                                    for (var sales in element.purchaseReturnDetails!) {
                                      returndAmount += (sales.returnAmount ?? 0);
                                    }
                                  }
                                  return Visibility(
                                    visible: (fromDate.isBefore(DateTime.parse(transaction[index].purchaseDate ?? '')) ||
                                            DateTime.parse(transaction[index].purchaseDate ?? '').isAtSameMomentAs(fromDate)) &&
                                        (toDate.isAfter(DateTime.parse(transaction[index].purchaseDate ?? '')) ||
                                            DateTime.parse(transaction[index].purchaseDate ?? '').isAtSameMomentAs(toDate)),
                                    child: GestureDetector(
                                      onTap: () {
                                        PurchaseInvoiceDetails(
                                          businessInfo: profile.value!,
                                          transitionModel: transaction[index],
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
                                                              color: transaction[index].dueAmount! <= 0
                                                                  ? const Color(0xff0dbf7d).withOpacity(0.1)
                                                                  : const Color(0xFFED1A3B).withOpacity(0.1),
                                                              borderRadius: const BorderRadius.all(Radius.circular(10))),
                                                          child: Text(
                                                            transaction[index].dueAmount! <= 0 ? lang.S.of(context).paid : lang.S.of(context).unPaid,
                                                            style: TextStyle(color: transaction[index].dueAmount! <= 0 ? const Color(0xff0dbf7d) : const Color(0xFFED1A3B)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      DateFormat.yMMMd().format(DateTime.parse(transaction[index].purchaseDate ?? '')),
                                                      style: const TextStyle(color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  '${lang.S.of(context).total} : $currency ${transaction[index].totalAmount.toString()}',
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
                                                      '${lang.S.of(context).returnAmount}: $currency $returndAmount',
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                    personalData.when(data: (data) {
                                                      return Row(
                                                        children: [
                                                          IconButton(
                                                              padding: EdgeInsets.zero,
                                                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                              onPressed: () async {
                                                                if ((Theme.of(context).platform == TargetPlatform.android)) {
                                                                  ///________Print_______________________________________________________

                                                                  PrintPurchaseTransactionModel model =
                                                                      PrintPurchaseTransactionModel(purchaseTransitionModel: transaction[index], personalInformationModel: data);

                                                                  await printerData.printPurchaseThermalInvoiceNow(
                                                                    transaction: model,
                                                                    productList: model.purchaseTransitionModel!.details,
                                                                    context: context,
                                                                  );
                                                                }
                                                              },
                                                              icon: const Icon(
                                                                FeatherIcons.printer,
                                                                color: Colors.grey,
                                                              )),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          businessData.when(data: (business) {
                                                            return IconButton(
                                                                padding: EdgeInsets.zero,
                                                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                                onPressed: () => GeneratePdf().generatePurchaseDocument(transaction[index], data, context, business),
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
                                                          })
                                                        ],
                                                      );
                                                    }, error: (e, stack) {
                                                      return Text(e.toString());
                                                    }, loading: () {
                                                      //return const Text('Loading');
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
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              lang.S.of(context).addNewPurchase,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20.0),
                            ),
                          );
                  }, error: (e, stack) {
                    return Text(e.toString());
                  }, loading: () {
                    return const Center(child: CircularProgressIndicator());
                  }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

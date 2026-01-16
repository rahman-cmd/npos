import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:collection/collection.dart';
import 'package:mobile_pos/Screens/Due%20Calculation/Providers/due_provider.dart';
import 'package:mobile_pos/Screens/invoice_details/due_invoice_details.dart';
import 'package:mobile_pos/Screens/invoice_details/purchase_invoice_details.dart';
import 'package:mobile_pos/Screens/invoice_details/sales_invoice_details_screen.dart';
import 'package:mobile_pos/Screens/party%20ledger/provider.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/pdf_report/ledger_report/ledger_report_pdf.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../constant.dart';
import '../../model/business_info_model.dart';
import '../../pdf_report/ledger_report/ledger_report_excel.dart';
import '../../widgets/build_date_selector/build_date_selector.dart';
import '../Sales/Repo/sales_repo.dart';
import 'model/party_leder_filer_param.dart';

class PartyLedgerScreen extends ConsumerStatefulWidget {
  final String partyId;
  final String partyName; // Passed for the Appbar title

  const PartyLedgerScreen({
    super.key,
    required this.partyId,
    required this.partyName,
  });

  @override
  ConsumerState<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends ConsumerState<PartyLedgerScreen> {
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> dateOptions = {
    'all': lang.S.current.all,
    'today': lang.S.current.today,
    'yesterday': lang.S.current.yesterday,
    'last_seven_days': lang.S.current.last7Days,
    'last_thirty_days': lang.S.current.last30Days,
    'current_month': lang.S.current.currentMonth,
    'last_month': lang.S.current.lastMonth,
    'current_year': lang.S.current.currentYear,
    'custom_date': lang.S.current.customerDate,
  };
  String selectedTime = 'all';
  // String selectedTime = 'today';
  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.refresh(dashboardInfoProvider(selectedTime.toLowerCase()));

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  bool _showCustomDatePickers = false; // Track if custom date pickers should be shown

  DateTime? fromDate;
  DateTime? toDate;

  String? _getDateRangeString() {
    if (selectedTime == 'all') {
      return null;
    }

    if (selectedTime != 'custom_date') {
      return selectedTime.toLowerCase();
    }

    if (fromDate != null && toDate != null) {
      final formattedFrom = DateFormat('yyyy-MM-dd').format(fromDate!);
      final formattedTo = DateFormat('yyyy-MM-dd').format(toDate!);
      return 'custom_date&from_date=$formattedFrom&to_date=$formattedTo';
    }

    return null;
  }

  Future<void> _selectedFormDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
      });
      if (toDate != null) refreshData(ref);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: fromDate ?? DateTime(2021),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
      });
      if (fromDate != null) refreshData(ref);
    }
  }

  // Helper to format date "27 Jan 2025"
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();

    final dateRangeString = _getDateRangeString();
    final filterParam = PartyLedgerFilterParam(
      partyId: widget.partyId,
      duration: dateRangeString,
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        ref.read(partyLedgerProvider(filterParam).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _lang = lang.S.of(context);
    final dateRangeString = _getDateRangeString();
    print('-----------party id-----------${widget.partyId}---filter: $dateRangeString');
    final filterParam = PartyLedgerFilterParam(
      partyId: widget.partyId,
      duration: dateRangeString,
    );

    final ledgerState = ref.watch(partyLedgerProvider(filterParam));

    final notifier = ref.read(partyLedgerProvider(filterParam).notifier);
    final businessData = ref.watch(businessInfoProvider);
    final saleTransactionData = ref.watch(salesTransactionProvider);
    final purchaseTransactionData = ref.watch(purchaseTransactionProvider);
    final dueTransactionData = ref.watch(dueCollectionListProvider);
    final _theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 30,
        title: Text(
          widget.partyName,
          style: _theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          businessData.when(
            data: (business) {
              return IconButton(
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (ledgerState.transactions.isNotEmpty) {
                    generateLedgerReportPdf(
                      context,
                      ledgerState.transactions,
                      business,
                      _showCustomDatePickers ? fromDate : null,
                      _showCustomDatePickers ? toDate : null,
                      selectedTime,
                    );
                  } else {
                    EasyLoading.showInfo(_lang.noTransactionToGeneratePdf);
                  }
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedPdf01,
                  color: kSecondayColor,
                ),
              );
            },
            error: (e, stack) => Center(child: Text(e.toString())),
            loading: () => Center(
              child: CircularProgressIndicator(),
            ),
          ),
          businessData.when(
            data: (business) {
              return IconButton(
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (ledgerState.transactions.isNotEmpty) {
                    generateLedgerReportExcel(
                      context,
                      ledgerState.transactions,
                      business,
                      _showCustomDatePickers ? fromDate : null,
                      _showCustomDatePickers ? toDate : null,
                      selectedTime,
                    );
                  } else {
                    EasyLoading.showInfo(_lang.generatePdf);
                  }
                },
                icon: SvgPicture.asset('assets/excel.svg'),
              );
            },
            error: (e, stack) => Center(child: Text(e.toString())),
            loading: () => Center(
              child: CircularProgressIndicator(),
            ),
          ),
          const SizedBox(width: 8),
          // --- Filter Dropdown ---
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 120,
              height: 32,
              child: DropdownButtonFormField2<String>(
                isExpanded: true,
                iconStyleData: IconStyleData(
                  icon: Icon(Icons.keyboard_arrow_down, color: kPeraColor, size: 20),
                ),
                value: selectedTime,
                items: dateOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _theme.textTheme.titleSmall?.copyWith(
                        color: kPeraColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTime = value!;
                    _showCustomDatePickers = selectedTime == 'custom_date';

                    if (_showCustomDatePickers) {
                      fromDate = DateTime.now().subtract(const Duration(days: 7));
                      toDate = DateTime.now();
                    }

                    if (selectedTime != 'custom_date') {
                      refreshData(ref);
                    }
                  });
                },
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 500,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  scrollbarTheme: ScrollbarThemeData(
                    radius: const Radius.circular(40),
                    thickness: WidgetStateProperty.all<double>(6),
                    thumbVisibility: WidgetStateProperty.all<bool>(true),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 6)),
              ),
            ),
          )
        ],
        bottom: _showCustomDatePickers
            ? PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Column(
                  children: [
                    Divider(thickness: 1, color: kBottomBorder, height: 1),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => _selectedFormDate(context),
                              child: buildDateSelector(
                                prefix: 'From',
                                date: fromDate != null ? DateFormat('dd MMMM yyyy').format(fromDate!) : 'Select Date',
                                theme: _theme,
                              ),
                            ),
                            SizedBox(width: 5),
                            RotatedBox(
                              quarterTurns: 1,
                              child: Container(
                                height: 1,
                                width: 22,
                                color: kPeraColor,
                              ),
                            ),
                            SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => _selectToDate(context),
                              child: buildDateSelector(
                                prefix: 'To',
                                date: toDate != null ? DateFormat('dd MMMM yyyy').format(toDate!) : 'Select Date',
                                theme: _theme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async => notifier.updateFilter(ledgerState.currentFilter),
        child: ledgerState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ledgerState.transactions.isEmpty
                ? Center(child: Text(_lang.noTransactionFound))
                : RefreshIndicator(
                    onRefresh: () async => notifier.updateFilter(ledgerState.currentFilter),
                    child: SingleChildScrollView(
                      controller: _scrollController, // keep infinite scroll
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal, // horizontal scroll
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Color(0xffF5F3F3).withValues(alpha: 0.5),
                          ),
                          dividerThickness: 1,
                          // --- Header -------------
                          columns: [
                            DataColumn(
                              label: Text(
                                _lang.date,
                                style: _theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                _lang.reference,
                                style: _theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                _lang.description,
                                style: _theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                _lang.creditIn,
                                style: _theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                _lang.debitOut,
                                style: _theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                _lang.balance,
                                style: _theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],

                          // --- Rows (converted from ListView rows) --- //
                          rows: [
                            ...ledgerState.transactions.map((data) {
                              return DataRow(
                                cells: [
                                  // 1. Date
                                  DataCell(
                                    Text(
                                      _formatDate(data.date),
                                      style: _theme.textTheme.bodyLarge?.copyWith(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    saleTransactionData.when(
                                      data: (sales) {
                                        return purchaseTransactionData.when(
                                          data: (purchases) {
                                            return dueTransactionData.when(
                                              data: (dueCollections) {
                                                return businessData.when(
                                                  data: (business) {
                                                    return InkWell(
                                                      onTap: () {
                                                        if (data.platform == 'Sales') {
                                                          final sale = sales.firstWhereOrNull((e) => e.id == data.id);
                                                          if (sale != null) {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => SalesInvoiceDetails(
                                                                  saleTransaction: sale,
                                                                  businessInfo: business,
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Sale not found')),
                                                            );
                                                          }
                                                        } else if (data.platform == 'Purchase') {
                                                          final purchase =
                                                              purchases.firstWhereOrNull((e) => e.id == data.id);
                                                          if (purchase != null) {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => PurchaseInvoiceDetails(
                                                                  transitionModel: purchase,
                                                                  businessInfo: business,
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Purchase not found')),
                                                            );
                                                          }
                                                        } else if (data.platform == 'Payment') {
                                                          final due =
                                                              dueCollections.firstWhereOrNull((e) => e.id == data.id);
                                                          if (due != null) {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => DueInvoiceDetails(
                                                                  dueCollection: due,
                                                                  personalInformationModel: business,
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Due Collection not found')),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      child: Align(
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          data.invoiceNumber ?? '-',
                                                          textAlign: TextAlign.center,
                                                          style: _theme.textTheme.bodyLarge?.copyWith(
                                                            color: Colors.red,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  loading: () => const Center(child: CircularProgressIndicator()),
                                                  error: (e, stack) => Center(child: Text(e.toString())),
                                                );
                                              },
                                              loading: () => const Center(child: CircularProgressIndicator()),
                                              error: (e, stack) => Center(child: Text(e.toString())),
                                            );
                                          },
                                          loading: () => const CircularProgressIndicator(),
                                          error: (e, stack) => Center(child: Text(e.toString())),
                                        );
                                      },
                                      loading: () => const CircularProgressIndicator(),
                                      error: (e, stack) => Center(child: Text(e.toString())),
                                    ),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        data.platform.toString(),
                                        textAlign: TextAlign.center,
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Credit
                                  DataCell(
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$currency${formatPointNumber(data.creditAmount ?? 0, addComma: true)}',
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Debit
                                  DataCell(
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$currency${formatPointNumber(data.debitAmount ?? 0, addComma: true)}',
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Balance
                                  DataCell(
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$currency${formatPointNumber(data.balance ?? 0, addComma: true)}',
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),

                            // --- Load More Loader Row --- //
                            if (ledgerState.isLoadMoreRunning)
                              const DataRow(
                                cells: [
                                  DataCell(
                                    Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                  ),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xffF5F3F3).withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _lang.totalBalance,
              style: _theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            Text(
              ledgerState.transactions.isNotEmpty
                  ? "$currency${formatPointNumber(ledgerState.transactions.last.balance ?? 0)}"
                  : "0",
              style: _theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

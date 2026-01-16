import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../Provider/profile_provider.dart';
import '../../../constant.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../GlobalComponents/sales_transaction_widget.dart';
import '../../http_client/custome_http_client.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../Home/home.dart';
import '../../service/check_user_role_permission_provider.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

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
    ref.refresh(getExpireDateProvider(ref));
    ref.refresh(thermalPrinterProvider);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
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
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Consumer(builder: (context, ref, __) {
            final providerData = ref.watch(salesTransactionProvider);
            final profile = ref.watch(businessInfoProvider);
            final permissionService = PermissionService(ref);
            return RefreshIndicator.adaptive(
              onRefresh: () => refreshData(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: providerData.when(data: (transaction) {
                  return transaction.isNotEmpty
                      ? providerData.when(
                          data: (transaction) {
                            if (transaction.isEmpty) {
                              return Center(
                                child: EmptyWidget(
                                  message: TextSpan(
                                    text: lang.S.of(context).addSale,
                                  ),
                                ),
                              );
                            }
                            return profile.when(
                              data: (shopDetails) {
                                if (!permissionService.hasPermission(Permit.salesRead.value)) {
                                  return Center(child: PermitDenyWidget());
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: transaction.length,
                                  itemBuilder: (context, index) {
                                    return salesTransactionWidget(
                                      context: context,
                                      ref: ref,
                                      businessInfo: shopDetails,
                                      sale: transaction[index],
                                      advancePermission: true,
                                      isFromSaleList: true,
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, stack) => Text(e.toString()),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, stack) => Text(e.toString()),
                        )
                      : Center(
                          child: EmptyWidget(
                          message: TextSpan(
                            text: lang.S.of(context).addSale,
                          ),
                        ));
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/Customers/Provider/customer_provider.dart';
import '../../../Const/api_config.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Provider/transactions_provider.dart';
import '../../../constant.dart';
import '../../../http_client/custome_http_client.dart';
import '../../../service/check_user_role_permission_provider.dart';

class InvoiceReturnRepo {
  ///__________Sales_return___________________________________________
  Future<bool?> createSalesReturn({
    required WidgetRef ref,
    required BuildContext context,
    required ReturnDataModel salesReturn,
  }) async {
    return _submitReturnRequest(
      ref: ref,
      context: context,
      urlPath: '/sales-return',
      body: salesReturn.toJson(),
      permission: Permit.saleReturnsCreate.value,
      successMessage: 'Sales Return Added successfully!',
      onSuccessRefresh: () {
        ref.refresh(salesTransactionProvider);
      },
    );
  }

  ///_________Purchase_return__________________________________
  Future<bool?> createPurchaseReturn({
    required WidgetRef ref,
    required BuildContext context,
    required ReturnDataModel returnData,
  }) async {
    return _submitReturnRequest(
      ref: ref,
      context: context,
      urlPath: '/purchases-return',
      body: returnData.toJson(purchase: true),
      permission: Permit.purchaseReturnsCreate.value,
      successMessage: 'Purchase Return Added successfully!',
      onSuccessRefresh: () {
        ref.refresh(purchaseTransactionProvider);
      },
    );
  }

  ///_________Common_Private_Method_to_Avoid_Duplication_______
  Future<bool?> _submitReturnRequest({
    required WidgetRef ref,
    required BuildContext context,
    required String urlPath,
    required Map<String, dynamic> body,
    required String permission,
    required String successMessage,
    required VoidCallback onSuccessRefresh,
  }) async {
    final uri = Uri.parse('${APIConfig.url}$urlPath');

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

      var response = await customHttpClient.post(
        url: uri,
        addContentTypeInHeader: true,
        body: jsonEncode(body),
        permission: permission,
      );

      final parsedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        EasyLoading.showSuccess(successMessage);

        // Refresh Common Providers
        ref.refresh(summaryInfoProvider);
        ref.refresh(partiesProvider);
        ref.refresh(productProvider);

        // Refresh Specific Provider
        onSuccessRefresh();

        return true;
      } else {
        _showError(context, parsedData['message'] ?? 'Something went wrong');
        return null;
      }
    } catch (error) {
      final errorMessage = error.toString().replaceFirst('Exception: ', '');
      _showError(context, errorMessage);
      return null;
    }
  }

  // Helper to show error snackbar
  void _showError(BuildContext context, String message) {
    EasyLoading.dismiss();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kMainColor,
      ),
    );
  }
}

class ReturnDataModel {
  final String? saleId;
  final List<num> returnQty;
  List<Map<String, dynamic>> payments;

  ReturnDataModel({
    required this.saleId,
    required this.returnQty,
    required this.payments,
  });

  Map<String, dynamic> toJson({bool purchase = false}) {
    return {
      purchase ? "purchase_id" : 'sale_id': saleId,
      'return_qty': returnQty.map((e) => e.toString()).toList(),
      'payments': payments,
    };
  }
}

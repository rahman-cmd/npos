// ignore_for_file: file_names, unused_element, unused_local_variable
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/product_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Provider/transactions_provider.dart';
import '../../../Repository/constant_functions.dart';
import '../../../model/sale_transaction_model.dart';
import '../../Customers/Provider/customer_provider.dart';

class InvoiceReturnRepo {
  Future<List<SalesTransactionModel>> fetchSalesList() async {
    final uri = Uri.parse('${APIConfig.url}/sales');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => SalesTransactionModel.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch Sales List');
    }
  }

  Future<SalesTransactionModel?> createSale({
    required WidgetRef ref,
    required BuildContext context,
    required num? partyId,
    required String? customerPhone,
    required String purchaseDate,
    required num discountAmount,
    required num totalAmount,
    required num dueAmount,
    required num vatAmount,
    required num vatPercent,
    required num paidAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartSaleProducts> products,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales');
    final requestBody = jsonEncode({
      'party_id': partyId,
      'customer_phone': customerPhone,
      'saleDate': purchaseDate,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'dueAmount': dueAmount,
      'paidAmount': paidAmount,
      'vat_amount': vatAmount,
      'vat_percent': vatPercent,
      'isPaid': isPaid,
      'paymentType': paymentType,
      'products': products.map((product) => product.toJson()).toList(),
    });

    try {
      var responseData = await http.post(
        uri,
        headers: {"Accept": 'application/json', 'Authorization': await getAuthToken(), 'Content-Type': 'application/json'},
        body: requestBody,
      );

      final parsedData = jsonDecode(responseData.body);
      print('SaleData: ${parsedData['data']}');

      if (responseData.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!');
        var data1 = ref.refresh(productProvider);
        var data2 = ref.refresh(partiesProvider);
        var data3 = ref.refresh(salesTransactionProvider);
        var data4 = ref.refresh(businessInfoProvider);
        ref.refresh(summaryInfoProvider);
        // Navigator.pop(context);
        return SalesTransactionModel.fromJson(parsedData['data']);
      } else {
        EasyLoading.dismiss().then(
          (value) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sales creation failed: ${parsedData['message']}')));
          },
        );
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss().then(
        (value) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
        },
      );
      return null;
    }
  }

  Future<void> updateSale({
    required WidgetRef ref,
    required BuildContext context,
    required num id,
    required num? partyId,
    required String purchaseDate,
    required num discountAmount,
    required num totalAmount,
    required num dueAmount,
    required num vatAmount,
    required num vatPercent,
    required num paidAmount,
    required bool isPaid,
    required String paymentType,
    required List<CartSaleProducts> products,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales/$id');
    final requestBody = jsonEncode({
      '_method': 'put',
      'party_id': partyId,
      'saleDate': purchaseDate,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'dueAmount': dueAmount,
      'paidAmount': paidAmount,
      'vat_amount': vatAmount,
      'vat_percent': vatPercent,
      'isPaid': isPaid,
      'paymentType': paymentType,
      'products': products.map((product) => product.toJson()).toList(),
    });

    try {
      var responseData = await http.post(
        uri,
        headers: {"Accept": 'application/json', 'Authorization': await getAuthToken(), 'Content-Type': 'application/json'},
        body: requestBody,
      );

      final parsedData = jsonDecode(responseData.body);
      print(responseData.statusCode);
      print(parsedData);

      if (responseData.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!').then((value) {
          var data1 = ref.refresh(productProvider);
          var data2 = ref.refresh(partiesProvider);
          var data3 = ref.refresh(salesTransactionProvider);
          var data4 = ref.refresh(businessInfoProvider);
          Navigator.pop(context);
        });
        // return PurchaseTransaction.fromJson(parsedData);
      } else {
        EasyLoading.dismiss().then((value) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sales creation failed: ${parsedData['message']}')));
        });
        return;
      }
    } catch (error) {
      EasyLoading.dismiss().then((value) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      });
      return;
    }
  }
}

class CartSaleProducts {
  final int productId;
  final num? price;
  final num? lossProfit;
  final num? quantities;

  CartSaleProducts({
    required this.productId,
    required this.price,
    required this.quantities,
    required this.lossProfit,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'price': price,
        'lossProfit': lossProfit,
        'quantities': quantities,
      };
}

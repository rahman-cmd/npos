//ignore_for_file: avoid_print,unused_local_variable
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Const/api_config.dart';

import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../../../http_client/customer_http_client_get.dart';
import '../Model/parties_model.dart';
import '../Provider/customer_provider.dart';
import '../add_customer.dart';

class PartyRepository {
  Future<List<Party>> fetchAllParties() async {
    final uri = Uri.parse('${APIConfig.url}/parties');
    CustomHttpClientGet clientGet = CustomHttpClientGet(client: http.Client());
    final response = await clientGet.get(url: uri);

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => Party.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch parties');
    }
  }

  Future<void> addParty({
    required WidgetRef ref,
    required BuildContext context,
    required Customer customer,
  }) async {
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);
    final uri = Uri.parse('${APIConfig.url}/parties');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();

    void addField(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        request.fields[key] = value;
      }
    }

    addField('name', customer.name);
    addField('phone', customer.phone);
    addField('type', customer.customerType);
    addField('email', customer.email);
    addField('address', customer.address);
    addField('opening_balance_type', customer.openingBalanceType);
    addField('opening_balance', customer.openingBalance?.toString());
    addField('credit_limit', customer.creditLimit?.toString());

    // Send billing and shipping address fields directly
    addField('billing_address[address]', customer.billingAddress);
    addField('billing_address[city]', customer.billingCity);
    addField('billing_address[state]', customer.billingState);
    addField('billing_address[zip_code]', customer.billingZipcode);
    addField('billing_address[country]', customer.billingCountry);

    addField('shipping_address[address]', customer.shippingAddress);
    addField('shipping_address[city]', customer.shippingCity);
    addField('shipping_address[state]', customer.shippingState);
    addField('shipping_address[zip_code]', customer.shippingZipcode);
    addField('shipping_address[country]', customer.shippingCountry);

    print('Party Data: ${request.fields}');

    final response = await customHttpClient.uploadFile(
      url: uri,
      fileFieldName: 'image',
      file: customer.image,
      fields: request.fields,
    );

    final responseData = await response.stream.bytesToString();
    print('${responseData}');
    final parsedData = jsonDecode(responseData);
    print('Party Added Response: $parsedData');
    request.fields.forEach((key, value) {
      print('$key: $value');
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added successfully!')));
      ref.refresh(partiesProvider); // Refresh party list
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Party creation failed: ${parsedData['message']}')),
      );
    }
  }

  Future<void> updateParty({
    required WidgetRef ref,
    required BuildContext context,
    required Customer customer,
  }) async {
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);
    final uri = Uri.parse('${APIConfig.url}/parties/${customer.id}');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();

    void addField(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        request.fields[key] = value;
      }
    }

    request.fields['_method'] = 'put';
    addField('name', customer.name);
    addField('phone', customer.phone);
    addField('type', customer.customerType);
    addField('email', customer.email);
    addField('address', customer.address);
    addField('opening_balance_type', customer.openingBalanceType);
    addField('opening_balance', customer.openingBalance?.toString());
    addField('credit_limit', customer.creditLimit?.toString());

    // Send billing and shipping address fields directly
    addField('billing_address[address]', customer.billingAddress);
    addField('billing_address[city]', customer.billingCity);
    addField('billing_address[state]', customer.billingState);
    addField('billing_address[zip_code]', customer.billingZipcode);
    addField('billing_address[country]', customer.billingCountry);

    addField('shipping_address[address]', customer.shippingAddress);
    addField('shipping_address[city]', customer.shippingCity);
    addField('shipping_address[state]', customer.shippingState);
    addField('shipping_address[zip_code]', customer.shippingZipcode);
    addField('shipping_address[country]', customer.shippingCountry);

    if (customer.image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', customer.image!.path));
    }

    final response = await customHttpClient.uploadFile(
      url: uri,
      fileFieldName: 'image',
      file: customer.image,
      fields: request.fields,
    );

    final responseData = await response.stream.bytesToString();
    final parsedData = jsonDecode(responseData);
    print('--- Sending Party Data ---');
    request.fields.forEach((key, value) {
      print('$key: $value');
    });
    if (customer.image != null) {
      print('Image path: ${customer.image!.path}');
    } else {
      print('No image selected');
    }
    print('---------------------------');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added successfully!')));
      ref.refresh(partiesProvider); // Refresh party list
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Party creation failed: ${parsedData['message']}')),
      );
    }
  }

  // Future<void> updateParty({
  //   required String id,
  //   required WidgetRef ref,
  //   required BuildContext context,
  //   required String name,
  //   required String phone,
  //   required String type,
  //   File? image,
  //   String? email,
  //   String? address,
  //   String? due,
  // }) async {
  //   final uri = Uri.parse('${APIConfig.url}/parties/$id');
  //   CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);
  //
  //   var request = http.MultipartRequest('POST', uri)
  //     ..headers['Accept'] = 'application/json'
  //     ..headers['Authorization'] = await getAuthToken();
  //
  //   request.fields['_method'] = 'put';
  //   request.fields['name'] = name;
  //   request.fields['phone'] = phone;
  //   request.fields['type'] = type;
  //   if (email != null) request.fields['email'] = email;
  //   if (address != null) request.fields['address'] = address;
  //   if (due != null) request.fields['due'] = due; // Convert due to string
  //   if (image != null) {
  //     request.files.add(http.MultipartFile.fromBytes('image', image.readAsBytesSync(), filename: image.path));
  //   }
  //
  //   // final response = await request.send();
  //   final response = await customHttpClient.uploadFile(url: uri, fields: request.fields, file: image, fileFieldName: 'image');
  //   final responseData = await response.stream.bytesToString();
  //
  //   final parsedData = jsonDecode(responseData);
  //
  //   if (response.statusCode == 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated Successfully!')));
  //     var data1 = ref.refresh(partiesProvider);
  //
  //     Navigator.pop(context);
  //     Navigator.pop(context);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Party Update failed: ${parsedData['message']}')));
  //   }
  // }

  Future<void> deleteParty({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/parties/$id';

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party deleted successfully')));

        var data1 = ref.refresh(partiesProvider);

        Navigator.pop(context); // Assuming you want to close the screen after deletion
        // Navigator.pop(context); // Assuming you want to close the screen after deletion
      } else {
        final parsedData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete party: ${parsedData['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> sendCustomerUdeSms({required num id, required BuildContext context}) async {
    CustomHttpClientGet clientGet = CustomHttpClientGet(client: http.Client());
    final uri = Uri.parse('${APIConfig.url}/parties/$id');

    final response = await clientGet.get(url: uri);
    EasyLoading.dismiss();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonDecode(response.body)['message'])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${jsonDecode((response.body))['message']}')));
    }
  }
}

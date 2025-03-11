import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Const/api_config.dart';

import '../../http_client/custome_http_client.dart';
import '../constant_functions.dart';

class BusinessUpdateRepository {
  Future<bool> updateProfile({
    required String id,
    required String name,
    required String categoryId,
    required BuildContext context,
    required WidgetRef ref,
    String? phone,
    String? vatNumber,
    String? vatTitle,
    File? image,
    String? address,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/business/$id');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();

    request.fields['_method'] = 'put';
    request.fields['companyName'] = name;
    request.fields['business_category_id'] = categoryId;
    if (phone != null) request.fields['phoneNumber'] = phone;
    if (address != null) request.fields['address'] = address;
    if (vatNumber != null) request.fields['vat_no'] = vatNumber;
    if (vatTitle != null) request.fields['vat_name'] = vatTitle;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('pictureUrl', image.readAsBytesSync(), filename: image.path));
    }
    print(request.fields);

    // final response = await request.send();
    final response = await customHttpClient.uploadFile(
      url: uri,
      fileFieldName: 'pictureUrl',
      file: image,
      fields: request.fields,
    );
    var da = await response.stream.bytesToString();
    print(response.statusCode);
    print(da);
    print(categoryId);

    if (response.statusCode == 200) {
      return true; // Update successful
    } else {
      return false;
    }
  }
}

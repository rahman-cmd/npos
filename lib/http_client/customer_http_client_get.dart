import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Screens/Authentication/Repo/logout_repo.dart';
import 'package:mobile_pos/http_client/subscription_expire_provider.dart';

import '../Repository/constant_functions.dart';
import '../service/check_user_role_permission_provider.dart';
import '../Screens/subscription/purchase_premium_plan_screen.dart';

class CustomHttpClientGet {
  final http.Client client;

  CustomHttpClientGet({
    required this.client,
  });
  Future<http.Response> get({
    required Uri url,
    Map<String, String>? headers,
    bool? addContentTypeInHeader,
  }) async {
    final http.Response response = await client.get(
      url,
      headers: headers ??
          {
            'Accept': 'application/json',
            'Authorization': await getAuthToken(),
            if (addContentTypeInHeader ?? false) 'Content-Type': 'application/json',
          },
    );

    if (response.statusCode == 401) {
      EasyLoading.showError('Token expire, You have to login again!');
      LogOutRepo().signOutApi();
    }

    return response;
  }
}

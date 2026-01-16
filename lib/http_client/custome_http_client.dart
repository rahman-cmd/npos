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

class CustomHttpClient {
  final http.Client client;
  final WidgetRef ref;
  final BuildContext context;

  CustomHttpClient({
    required this.client,
    required this.ref,
    required this.context,
  });
  bool hasPermission(String permission) {
    final notifier = ref.read(userPermissionProvider.notifier);
    final permissions = ref.read(userPermissionProvider);
    print('Permissions-----: $permissions');
    if (permissions == null || permissions.isEmpty) {
      print('No permissions, returning false');
      return true;
    }
    final hasIt = notifier.has(permission);
    print('Permission----- $permission granted: $hasIt');
    print('🔒 Checking permission "$permission" → ${hasIt ? "✅ Allowed" : "❌ Denied"}');
    return hasIt;
  }

  /// POST request
  Future<http.Response> post({
    required Uri url,
    Map<String, String>? headers,
    bool? addContentTypeInHeader,
    Object? body,
    String? permission,
  }) async {
    final subscriptionState = ref.read(subscriptionProvider);

    if (subscriptionState.isExpired) {
      EasyLoading.dismiss();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchasePremiumPlanScreen(
            isExpired: true,
            isCameBack: true,
            enrolledPlan: null,
            willExpire: DateTime(2025, 2, 28).toString(),
          ),
        ),
      );
      return http.Response(jsonEncode({'error': 'Subscription expired'}), 403);
    }

    if (permission != null) {
      if (!hasPermission(permission)) {
        return http.Response(jsonEncode({'error': 'Permission denied'}), 403);
      }
    }

    final http.Response response = await client.post(
      url,
      headers: headers ??
          {
            'Accept': 'application/json',
            'Authorization': await getAuthToken(),
            if (addContentTypeInHeader ?? false) 'Content-Type': 'application/json',
          },
      body: body,
    );

    if (response.statusCode == 401) {
      EasyLoading.showError('Token expire, You have to login again!');
      LogOutRepo().signOutApi();
    }

    return response;
  }

  /// DELETE request
  Future<http.Response> delete({
    required Uri url,
    Map<String, String>? headers,
    String? permission,
  }) async {
    final subscriptionState = ref.read(subscriptionProvider);

    if (subscriptionState.isExpired) {
      EasyLoading.dismiss();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchasePremiumPlanScreen(
            isExpired: true,
            isCameBack: true,
            enrolledPlan: null,
            willExpire: DateTime(2025, 2, 28).toString(),
          ),
        ),
      );
      return http.Response(jsonEncode({'error': 'Subscription expired'}), 403);
    }

    if (permission != null) {
      if (!hasPermission(permission)) {
        return http.Response(jsonEncode({'error': 'Permission denied'}), 403);
      }
    }
    final http.Response response = await client.delete(
      url,
      headers: headers ??
          {
            'Accept': 'application/json',
            'Authorization': await getAuthToken(),
          },
    );
    if (response.statusCode == 401) {
      EasyLoading.showError('Token expire, You have to login again!');
      LogOutRepo().signOutApi();
    }

    return response;
  }

  /// Upload file
  Future<http.StreamedResponse> uploadFile({
    required Uri url,
    File? file,
    String? contentType,
    String? fileFieldName,
    Map<String, String>? fields,
    String? permission,
  }) async {
    final subscriptionState = ref.read(subscriptionProvider);

    if (subscriptionState.isExpired) {
      EasyLoading.dismiss();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchasePremiumPlanScreen(
            isExpired: true,
            isCameBack: true,
            enrolledPlan: null,
            willExpire: DateTime(2025, 2, 28).toString(),
          ),
        ),
      );
      throw Exception("Subscription Expired");
    }

    if (permission != null) {
      if (!hasPermission(permission)) {
        throw Exception("Permission denied");
      }
    }

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = await getAuthToken();
    request.headers['Accept'] = 'application/json';

    if (contentType != null) {
      request.headers['Content-Type'] = contentType;
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (file != null && fileFieldName != null) {
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(fileFieldName, stream, length, filename: file.path);
      request.files.add(multipartFile);
    }

    final http.StreamedResponse response = await request.send();

    if (response.statusCode == 401) {
      EasyLoading.showError('Token expire, You have to login again!');
      LogOutRepo().signOutApi();
    }

    return response;
  }

  /// Upload multiple files with fields (USED FOR PROFILE UPDATE)
  Future<http.StreamedResponse> uploadMultipleFiles({
    required Uri url,
    required Map<String, String> fields,
    required Map<String, File> files,
    String? permission,
  }) async {
    final subscriptionState = ref.read(subscriptionProvider);

    if (subscriptionState.isExpired) {
      EasyLoading.dismiss();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchasePremiumPlanScreen(
            isExpired: true,
            isCameBack: true,
            enrolledPlan: null,
            willExpire: DateTime(2025, 2, 28).toString(),
          ),
        ),
      );
      throw Exception("Subscription Expired");
    }

    if (permission != null && !hasPermission(permission)) {
      throw Exception("Permission denied");
    }

    final request = http.MultipartRequest('POST', url)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken()
      ..fields.addAll(fields);

    /// Attach multiple files
    for (final entry in files.entries) {
      final file = entry.value;
      request.files.add(
        await http.MultipartFile.fromPath(
          entry.key,
          file.path,
          filename: file.path.split('/').last,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode == 401) {
      EasyLoading.showError('Token expire, You have to login again!');
      LogOutRepo().signOutApi();
    }

    return response;
  }
}

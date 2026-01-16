import 'dart:convert';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

import '../../../../Const/api_config.dart';
import '../../../../Repository/constant_functions.dart';
import '../../../../http_client/customer_http_client_get.dart';
import '../model/get_product_setting_model.dart';
import '../model/product_setting_model.dart';

class ProductSettingRepo {
  // add/update setting
  Future<bool> updateProductSetting({required UpdateProductSettingModel data}) async {
    EasyLoading.show(status: 'Updating');
    final prefs = await SharedPreferences.getInstance();

    final url = Uri.parse('${APIConfig.url}/product-settings');

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    request.fields['show_product_name'] = '1';
    request.fields['show_product_code'] = data.productCode.toString();
    request.fields['show_product_stock'] = data.productStock.toString();
    request.fields['show_product_sale_price'] = data.salePrice.toString();
    request.fields['show_product_dealer_price'] = data.dealerPrice.toString();
    request.fields['show_product_wholesale_price'] = data.wholesalePrice.toString();
    request.fields['show_product_unit'] = data.unit.toString();
    request.fields['show_product_brand'] = data.brand.toString();
    request.fields['show_product_category'] = data.category.toString();
    request.fields['show_product_manufacturer'] = data.manufacturer.toString();
    request.fields['show_product_image'] = data.image.toString();
    request.fields['show_expire_date'] = data.showExpireDate.toString();
    request.fields['show_alert_qty'] = data.alertQty.toString();
    request.fields['show_vat_id'] = data.vatId.toString();
    request.fields['show_vat_type'] = data.vatType.toString();
    request.fields['show_exclusive_price'] = data.exclusivePrice.toString();
    request.fields['show_inclusive_price'] = data.inclusivePrice.toString();
    request.fields['show_profit_percent'] = data.profitPercent.toString();
    request.fields['show_batch_no'] = data.batchNo.toString();
    request.fields['show_mfg_date'] = data.showManufactureDate.toString();
    request.fields['show_model_no'] = data.model.toString();
    request.fields['show_product_type_single'] = data.showSingle.toString();
    request.fields['show_product_type_variant'] = data.showVariant.toString();
    request.fields['show_action'] = data.showAction.toString();
    request.fields['default_expired_date'] = data.defaultExpireDate.toString();
    request.fields['default_mfg_date'] = data.defaultManufactureDate.toString();
    request.fields['expire_date_type'] = data.expireDateType.toString();
    request.fields['mfg_date_type'] = data.manufactureDateType.toString();
    request.fields['mfg_date_type'] = data.manufactureDateType.toString();
    request.fields['show_product_type_combo'] = data.showProductTypeCombo.toString();
    request.fields['show_warehouse'] = data.showWarehouse.toString();
    request.fields['show_rack'] = data.showRack.toString();
    request.fields['show_shelf'] = data.showShelf.toString();
    request.fields['show_guarantee'] = data.showGuaranty.toString();
    request.fields['show_warranty'] = data.showWarranty.toString();

    try {
      var response = await request.send();

      var responseData = await http.Response.fromStream(response);
      EasyLoading.dismiss();
      print(response.statusCode);
      if (response.statusCode == 200) {
        return true;
      } else {
        var data = jsonDecode(responseData.body);
        EasyLoading.showError(data['message'] ?? 'Failed to update');
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
      return false;
    }
  }

  Future<GetProductSettingModel> fetchProductSetting() async {
    CustomHttpClientGet clientGet = CustomHttpClientGet(client: http.Client());
    final url = Uri.parse('${APIConfig.url}/product-settings');

    try {
      var response = await clientGet.get(url: url);
      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return GetProductSettingModel.fromJson(jsonData);
      } else {
        var data = jsonDecode(response.body);
        EasyLoading.showError(data['message'] ?? 'Failed to Setting');
        throw Exception(data['message'] ?? 'Failed to fetch Setting');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error: ${e.toString()}');
      throw Exception('Error: ${e.toString()}');
    }
  }
}

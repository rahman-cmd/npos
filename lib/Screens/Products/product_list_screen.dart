// File: product_list.dart (Refactored and Cleaned)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:icons_plus/icons_plus.dart';

// --- Local Imports ---
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Products/product_details.dart';
import 'package:mobile_pos/Screens/Products/product_setting/provider/setting_provider.dart';
import 'package:mobile_pos/Screens/product%20variation/product_variation_list_screen.dart';
import 'package:mobile_pos/Screens/product_unit/unit_list.dart';
import 'package:mobile_pos/Screens/shelfs/shelf_list_screen.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:screenshot/screenshot.dart';
import '../../GlobalComponents/bar_code_scaner_widget.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../service/check_actions_when_no_branch.dart';
import '../../service/check_user_role_permission_provider.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../barcode/gererate_barcode.dart';
import '../product racks/product_racks_list.dart';
import '../product_brand/brands_list.dart';
import '../product_category/product_category_list_screen.dart';
import '../product_model/product_model_list.dart';
import '../product_category/provider/product_category_provider/product_unit_provider.dart';
import 'Repo/product_repo.dart';
import 'add product/add_product.dart';
import 'bulk product upload/bulk_product_upload_screen.dart';
import '../hrm/widgets/deleteing_alart_dialog.dart';

class ProductList extends ConsumerStatefulWidget {
  const ProductList({super.key});

  @override
  ConsumerState<ProductList> createState() => _ProductListState();
}

class _ProductListState extends ConsumerState<ProductList> {
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _productRepo = ProductRepo(); // Instantiate repo once

  // --- Data Refresh Logic ---
  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    // Invalidate main providers to force reload
    ref.invalidate(productProvider);
    ref.invalidate(categoryProvider);
    ref.invalidate(fetchSettingProvider);

    // Wait for reload (optional, but good for UX)
    await Future.delayed(const Duration(milliseconds: 500));
    _isRefreshing = false;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Helper Widgets ---

  // Builds the main context menu for product management tasks
  Widget _buildProductMenu() {
    final _theme = Theme.of(context);

    // Helper function to build consistent menu items
    PopupMenuItem<void> buildItem(
        {required VoidCallback onTap, List<List<dynamic>>? hugeIcons, IconData? icon, required String text}) {
      return PopupMenuItem(
        onTap: onTap,
        child: Row(
          children: [
            hugeIcons != null
                ? HugeIcon(
                    icon: hugeIcons,
                    color: kPeraColor,
                    size: 20,
                  )
                : Icon(
                    icon,
                    color: kPeraColor,
                    size: 20,
                  ),
            const SizedBox(width: 8),
            Text(
              text,
              style: _theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<void>(
      itemBuilder: (context) => [
        buildItem(
          onTap: () => const CategoryList(isFromProductList: true).launch(context),
          hugeIcons: HugeIcons.strokeRoundedAddToList,
          text: lang.S.of(context).productCategory,
        ),
        buildItem(
          onTap: () => const BrandsList(isFromProductList: true).launch(context),
          hugeIcons: HugeIcons.strokeRoundedSecurityCheck,
          text: lang.S.of(context).brand,
        ),
        buildItem(
          onTap: () => const ProductModelList(fromProductList: true).launch(context),
          hugeIcons: HugeIcons.strokeRoundedDrawingMode,
          text: lang.S.of(context).model,
        ),
        buildItem(
          onTap: () => const UnitList(isFromProductList: true).launch(context),
          hugeIcons: HugeIcons.strokeRoundedCells,
          text: lang.S.of(context).productUnit,
        ),
        buildItem(
          onTap: () => const ProductShelfList(isFromProductList: true).launch(context),
          icon: Bootstrap.bookshelf,
          text: lang.S.of(context).shelf,
        ),
        buildItem(
          onTap: () => const ProductRackList(isFromProductList: true).launch(context),
          icon: Bootstrap.hdd_rack,
          text: lang.S.of(context).racks,
        ),
        buildItem(
          onTap: () => const ProductVariationList().launch(context),
          hugeIcons: HugeIcons.strokeRoundedPackage,
          text: lang.S.of(context).variations,
        ),
        // const PopupMenuDivider(),
        buildItem(
          onTap: () async {
            bool result = await checkActionWhenNoBranch(ref: ref, context: context);
            if (result) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BulkUploader(),
                ),
              );
            }
          },
          hugeIcons: HugeIcons.strokeRoundedInboxUpload,
          text: lang.S.of(context).bulk,
        ),
        buildItem(
          onTap: () => const BarcodeGeneratorScreen().launch(context),
          hugeIcons: HugeIcons.strokeRoundedBarCode01,
          text: lang.S.of(context).barcodeGen,
        ),
      ],
      offset: const Offset(0, 40),
      color: kWhite,
      padding: EdgeInsets.zero,
      elevation: 2,
    );
  }

  // Builds the search and barcode scanner input field
  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Flexible(
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: lang.S.of(context).searchH,
                prefixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(start: 16),
                  child: Icon(
                    AntDesign.search_outline,
                    color: kPeraColor,
                  ),
                ),
                contentPadding: EdgeInsetsDirectional.zero,
                visualDensity: VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
              onChanged: (value) {
                // No need for setState here as controller listener already handles it
              },
            ),
          ),
          SizedBox(width: 10),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: kMainColor50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BarcodeScannerWidget(
                    onBarcodeFound: (String code) {
                      setState(() {
                        _searchController.text = code;
                        _searchQuery = code;
                      });
                    },
                  ),
                );
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedIrisScan,
                color: kMainColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the main list of products
  Widget _buildProductList(List<dynamic> products) {
    final filteredProducts = products.where((product) {
      final query = _searchQuery.toLowerCase();
      final name = product.productName?.toLowerCase() ?? '';
      final code = product.productCode?.toLowerCase() ?? '';
      return name.contains(query) || code.contains(query);
    }).toList();

    final permissionService = PermissionService(ref);
    final _theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    if (!permissionService.hasPermission(Permit.productsRead.value)) {
      return const Center(child: PermitDenyWidget());
    }

    if (filteredProducts.isEmpty && _searchQuery.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Text(
            lang.S.of(context).addProduct,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          ),
        ),
      );
    }

    if (filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(lang.S.of(context).noProductMatchYourSearch),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProducts.length,
      itemBuilder: (_, i) {
        final product = filteredProducts[i];

        // Helper function for building PopupMenuItems (Edit/Delete)
        PopupMenuItem<int> buildActionItem(
            {required int value, required IconData icon, required String text, required VoidCallback onTap}) {
          return PopupMenuItem(
            onTap: onTap,
            value: value,
            child: Row(
              children: [
                Icon(icon, color: kGreyTextColor),
                const SizedBox(width: 10),
                Text(text, style: _theme.textTheme.bodyMedium?.copyWith(color: kGreyTextColor)),
              ],
            ),
          );
        }

        return ListTile(
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails(details: product))),
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          leading: product.productPicture == null
              ? CircleAvatarWidget(
                  name: product.productName,
                  size: const Size(50, 50),
                )
              : Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage('${APIConfig.domain}${product.productPicture!}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  product.productName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                product.productType == 'combo'
                    ? '$currency${product.productSalePrice.toString()}'
                    : "$currency${product.stocks != null && product.stocks!.isNotEmpty && product.stocks!.first.productSalePrice != null ? product.stocks!.first.productSalePrice : '0'}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${lang.S.of(context).type} : ${product.productType == 'single' ? lang.S.of(context).single : product.productType == 'variant' ? locale == 'en' ? 'Variant' : lang.S.of(context).variations : product.productType == 'combo' ? lang.S.of(context).combo : product.productType}",
                style: _theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: kPeraColor,
                ),
              ),
              Text.rich(
                TextSpan(
                    text: '${lang.S.of(context).stock} : ',
                    style: _theme.textTheme.bodyMedium?.copyWith(
                      color: kPeraColor,
                    ),
                    children: [
                      TextSpan(
                          text: product.productType == 'combo'
                              ? lang.S.of(context).combo
                              : '${product.stocksSumProductStock ?? '0'}',
                          style: _theme.textTheme.bodyMedium?.copyWith(
                            color: DAppColors.kSuccess,
                          ))
                    ]),
              ),
            ],
          ),
          trailing: SizedBox(
            width: 30,
            child: PopupMenuButton<int>(
              style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
              itemBuilder: (context) => [
                // Edit Action
                buildActionItem(
                  value: 1,
                  icon: IconlyBold.edit,
                  text: lang.S.of(context).edit,
                  onTap: () async {
                    bool result = await checkActionWhenNoBranch(ref: ref, context: context);
                    if (!result) return;
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddProduct(productModel: product)));
                  },
                ),
                // Delete Action
                buildActionItem(
                  value: 2,
                  icon: IconlyBold.delete,
                  text: lang.S.of(context).delete,
                  onTap: () async {
                    bool confirmDelete = await showDeleteConfirmationDialog(context: context, itemName: 'product');
                    if (confirmDelete) {
                      EasyLoading.show(status: lang.S.of(context).deleting);
                      await _productRepo.deleteProduct(id: product.id.toString(), context: context, ref: ref);
                      // Refresh will happen automatically if repo is implemented correctly
                    }
                  },
                ),
              ],
              offset: const Offset(0, 40),
              color: kWhite,
              padding: EdgeInsets.zero,
              elevation: 2,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return Divider(color: const Color(0xff808191).withAlpha(50));
      },
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: kWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(lang.S.of(context).productList),
          actions: [_buildProductMenu()],
          toolbarHeight: 80,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(40),
            child: _buildSearchInput(),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kMainColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          onPressed: () async {
            bool result = await checkActionWhenNoBranch(ref: ref, context: context);
            if (result) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddProduct()));
            }
          },
          child: const Icon(Icons.add, color: kWhite),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: Consumer(builder: (context, ref, __) {
            final providerData = ref.watch(productProvider);
            // This is the outer check, but the main data display is inside providerData.when
            final businessInfo = ref.watch(businessInfoProvider);

            return businessInfo.when(
              data: (_) => providerData.when(
                data: (products) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildProductList(products),
                ),
                error: (e, stack) => Center(child: Text('Error loading products: ${e.toString()}')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              error: (e, stack) => Center(child: Text('Error loading business info: ${e.toString()}')),
              loading: () => const Center(child: CircularProgressIndicator()),
            );
          }),
        ),
      ),
    );
  }
}

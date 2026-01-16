import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/Screens/Products/Repo/product_repo.dart';
import 'package:mobile_pos/Screens/Products/product_setting/product_setting_drawer.dart';
import 'package:mobile_pos/Screens/Products/product_setting/provider/setting_provider.dart';
import 'package:mobile_pos/Screens/Products/add%20product/single_product_form.dart';
import 'package:mobile_pos/Screens/Products/add%20product/variant_product_form.dart';
import 'package:mobile_pos/Screens/product_category/product_category_list_screen.dart';
import 'package:mobile_pos/Screens/product_unit/model/unit_model.dart' as unit;
import 'package:mobile_pos/Screens/product_unit/unit_list.dart';
import 'package:mobile_pos/Screens/warehouse/warehouse_model/warehouse_list_model.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import '../../../Const/api_config.dart';
import '../../../GlobalComponents/bar_code_scaner_widget.dart';
import '../../../GlobalComponents/glonal_popup.dart';
import '../../../Provider/product_provider.dart';
import '../../../constant.dart';
import '../../../widgets/dotted_border/custom_dotted_border.dart';
import '../../../service/check_user_role_permission_provider.dart';
import '../../product racks/model/product_racks_model.dart';
import '../../product racks/provider/product_recks_provider.dart';
import '../../product variation/model/product_variation_model.dart';
import '../../product_brand/brands_list.dart';
import '../../product_brand/model/brands_model.dart' as brand;
import '../../product_category/model/category_model.dart';
import '../../product_model/model/product_models_model.dart' as model;
import '../../product_model/product_model_list.dart';
import '../../vat_&_tax/model/vat_model.dart';
import '../../vat_&_tax/provider/text_repo.dart';
import '../../warehouse/warehouse_provider/warehouse_provider.dart';
import 'combo_product_form.dart';
import 'modle/create_product_model.dart';

class AddProduct extends ConsumerStatefulWidget {
  const AddProduct({super.key, this.productModel});

  final Product? productModel;
  @override
  AddProductState createState() => AddProductState();
}

class AddProductState extends ConsumerState<AddProduct> {
  // This list holds the stocks for Variants (and potentially Single if edited via list)
  List<StockDataModel> variantStocks = [];
  List<ComboProductModel> comboList = [];
  List<String?> variationIds = [];

  CategoryModel? selectedCategory;
  brand.Brand? selectedBrand;
  model.Data? selectedModel;
  unit.Unit? selectedUnit;

  late String productName, productStock, productSalePrice, productPurchasePrice, productCode;
  String? selectedExpireDate;
  String? selectedManufactureDate;

  // Controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController productUnitController = TextEditingController();
  TextEditingController productStockController = TextEditingController();
  TextEditingController salePriceController = TextEditingController();
  TextEditingController discountPriceController = TextEditingController();
  TextEditingController purchaseExclusivePriceController = TextEditingController();
  TextEditingController profitMarginController = TextEditingController();
  TextEditingController purchaseInclusivePriceController = TextEditingController();
  TextEditingController productCodeController = TextEditingController();
  TextEditingController wholeSalePriceController = TextEditingController();
  TextEditingController dealerPriceController = TextEditingController();
  TextEditingController manufacturerController = TextEditingController();

  TextEditingController stockAlertController = TextEditingController();
  TextEditingController expireDateController = TextEditingController();
  TextEditingController manufactureDateController = TextEditingController();
  TextEditingController productBatchNumberController = TextEditingController();
  TextEditingController modelController = TextEditingController();
  TextEditingController warrantyController = TextEditingController();
  TextEditingController guaranteeController = TextEditingController();
  TextEditingController batchNumberController = TextEditingController();
  TextEditingController warehouseController = TextEditingController();
  TextEditingController variationManufacturerDateController = TextEditingController();
  TextEditingController variationExpiredDateController = TextEditingController();
  TextEditingController variantNameController = TextEditingController();
  TextEditingController variantBatchNoController = TextEditingController();
  TextEditingController comboProfitMarginController = TextEditingController();
  TextEditingController comboSalePriceController = TextEditingController();

  void initializeControllers() {
    if (widget.productModel != null) {
      // --- 1. Basic Product Info ---
      nameController = TextEditingController(text: widget.productModel?.productName ?? '');
      previousProductImage = widget.productModel?.productPicture;
      productCodeController.text = widget.productModel?.productCode ?? '';
      manufacturerController.text = widget.productModel?.productManufacturer ?? '';
      stockAlertController.text = widget.productModel?.alertQty.toString() ?? ''; // Used for stock alert quantity

      // --- 2. Dropdown (Related Models) Initialization ---
      if (widget.productModel?.category != null) {
        categoryController = TextEditingController(text: widget.productModel?.category?.categoryName ?? '');
        selectedCategory = CategoryModel(id: widget.productModel?.category?.id);
      }
      if (widget.productModel?.brand != null) {
        brandController = TextEditingController(text: widget.productModel?.brand?.brandName ?? '');
        selectedBrand = brand.Brand(id: widget.productModel?.brand?.id);
      }
      if (widget.productModel?.unit != null) {
        productUnitController = TextEditingController(text: widget.productModel?.unit?.unitName ?? '');
        selectedUnit = unit.Unit(id: widget.productModel?.unit?.id);
      }
      // Assuming model.Data and ProductModelInfo are structurally similar or compatible
      if (widget.productModel?.modelId != null && widget.productModel?.productModel != null) {
        modelController = TextEditingController(text: widget.productModel?.productModel?.name ?? '');
        selectedModel = model.Data(id: widget.productModel?.modelId);
      }

      // --- 3. Rack, Shelf, Warehouse Initialization (Setting IDs for later matching in build) ---
      // NOTE: We only initialize the target IDs/objects here. The actual selection in the Dropdown
      // is handled in the build method once the corresponding Provider data is available.

      // Set initial type
      _selectedType = widget.productModel?.productType == 'variant'
          ? ProductType.variant
          : widget.productModel?.productType == 'combo'
              ? ProductType.combo
              : ProductType.single;

      // --- 4. Tax/Price/Profit Logic ---
      selectedTaxType = widget.productModel?.vatType ?? "exclusive";
      num firstStockPurchasePrice = widget.productModel?.stocks?.firstOrNull?.productPurchasePrice ?? 0;
      num vatAmount = widget.productModel?.vatAmount ?? 0;

      // Set selectedTax (The full VatModel object matching vatId will be fetched in the build function's taxesData.whenData)
      if (widget.productModel?.vatId != null && widget.productModel?.vat != null) {
        // Assuming your ProductModel Vat object is compatible with VatModel
        // Or we rely entirely on the build method's logic to find the VatModel from the provider list.
        // For simplicity, we keep the initialization logic clean and rely on the build.
      }

      // Purchase Price Calculation
      if (selectedTaxType.toLowerCase() == 'exclusive') {
        purchaseExclusivePriceController.text = firstStockPurchasePrice.toStringAsFixed(2);
        purchaseInclusivePriceController.text = (firstStockPurchasePrice + vatAmount).toStringAsFixed(2);
      } else {
        purchaseInclusivePriceController.text = firstStockPurchasePrice.toStringAsFixed(2);
        purchaseExclusivePriceController.text = (firstStockPurchasePrice - vatAmount).toStringAsFixed(2);
      }

      // Profit and Sale Price
      num profitPercent = widget.productModel?.stocks?.firstOrNull?.profitPercent ?? 0;
      if (profitPercent.isNaN || profitPercent.isInfinite) {
        profitMarginController.text = '0.00';
      } else {
        profitMarginController.text = profitPercent.toStringAsFixed(2);
      }
      salePriceController.text = widget.productModel?.stocks?.firstOrNull?.productSalePrice?.toString() ?? '';
      wholeSalePriceController.text =
          widget.productModel?.stocks?.firstOrNull?.productWholeSalePrice?.toStringAsFixed(2) ?? '';
      dealerPriceController.text =
          widget.productModel?.stocks?.firstOrNull?.productDealerPrice?.toStringAsFixed(2) ?? '';

      // --- 5. Date Fields ---
      if (widget.productModel?.stocks?.firstOrNull?.expireDate != null) {
        // The API returns expire_date at the product level, but also in stocks. Using stocks for consistency with SingleProductForm
        expireDateController.text =
            DateFormat.yMd().format(DateTime.parse(widget.productModel!.stocks!.first.expireDate.toString()));
        selectedExpireDate = widget.productModel!.stocks!.first.expireDate?.toString();
      }
      if (widget.productModel?.stocks?.firstOrNull?.mfgDate != null) {
        manufactureDateController.text =
            DateFormat.yMd().format(DateTime.parse(widget.productModel!.stocks!.first.mfgDate.toString()));
        selectedManufactureDate = widget.productModel?.stocks?.first.mfgDate?.toString();
      }

      // --- 6. Warranty & Guarantee ---
      final warrantyInfo = widget.productModel?.warrantyGuaranteeInfo;
      if (warrantyInfo != null) {
        warrantyController.text = warrantyInfo.warrantyDuration?.toString() ?? '';
        selectedTimeWarranty = warrantyInfo.warrantyUnit ?? 'Days';
        guaranteeController.text = warrantyInfo.guaranteeDuration?.toString() ?? '';
        selectedTimeGuarantee = warrantyInfo.guaranteeUnit ?? 'Days';
      }

      // --- 7. Stock Data Mapping (Based on _selectedType) ---
      // ... [Existing SINGLE, VARIANT, COMBO mapping logic] ...

      if (_selectedType == ProductType.single && widget.productModel!.stocks!.isNotEmpty) {
        batchNumberController.text = widget.productModel!.stocks!.first.batchNo ?? '';
        productStockController.text = widget.productModel!.stocks!.first.productStock.toString();
      }

      if (_selectedType == ProductType.variant &&
          widget.productModel!.stocks != null &&
          widget.productModel!.stocks!.isNotEmpty) {
        variantStocks = widget.productModel!.stocks!.map((e) {
          final inclusivePrice = selectedTaxType.toLowerCase() == 'exclusive'
              ? (e.productPurchasePrice ?? 0) + vatAmount
              : (e.productPurchasePrice ?? 0);
          final exclusivePrice = selectedTaxType.toLowerCase() == 'exclusive'
              ? (e.productPurchasePrice ?? 0)
              : (e.productPurchasePrice ?? 0) - vatAmount;

          return StockDataModel(
            stockId: e.id.toString(),
            batchNo: e.batchNo,
            productStock: e.productStock.toString(),
            exclusivePrice: exclusivePrice.toStringAsFixed(2),
            inclusivePrice: inclusivePrice.toStringAsFixed(2),
            profitPercent: e.profitPercent.toString(),
            productSalePrice: e.productSalePrice.toString(),
            productWholeSalePrice: e.productWholeSalePrice.toString(),
            productDealerPrice: e.productDealerPrice.toString(),
            expireDate: e.expireDate,
            mfgDate: e.mfgDate,
            variantName: e.variantName,
            variationData: e.variationData,
            warehouseId: (e.warehouseId != null) ? e.warehouseId?.toString() : null,
          );
        }).toList();
      }

      if (_selectedType == ProductType.combo) {
        comboProfitMarginController.text = widget.productModel?.profitPercent?.toString() ?? '';
        comboSalePriceController.text = widget.productModel?.productSalePrice?.toString() ?? '';

        if (widget.productModel?.comboProducts != null && widget.productModel!.comboProducts!.isNotEmpty) {
          comboList = widget.productModel!.comboProducts!.map((e) {
            return ComboProductModel(
              stockId: e.stockId.toString(),
              purchasePrice: e.purchasePrice.toString(),
              quantity: e.quantity.toString(),
            );
          }).toList();
        }
      }
    }
  }

  @override
  void dispose() {
    // ... [Keep existing dispose calls] ...
    nameController.dispose();
    categoryController.dispose();
    brandController.dispose();
    productUnitController.dispose();
    productStockController.dispose();
    salePriceController.dispose();
    discountPriceController.dispose();
    purchaseExclusivePriceController.dispose();
    profitMarginController.dispose();
    purchaseInclusivePriceController.dispose();
    productCodeController.dispose();
    wholeSalePriceController.dispose();
    dealerPriceController.dispose();
    manufacturerController.dispose();
    modelController.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();
  XFile? pickedImage;
  String? previousProductImage;
  VatModel? selectedTax;
  String selectedTaxType = 'exclusive';
  List<String> codeList = [];
  String promoCodeHint = 'Enter Product Code';
  RackData? selectedRack;
  Shelf? selectedShelf;
  WarehouseData? selectedWarehouse;
  final kLoader = Center(child: CircularProgressIndicator(strokeWidth: 2));

  String? selectedTimeWarranty = 'Days';
  String? selectedTimeGuarantee = 'Days';
  List<int?> selectedVariation = [];
  List<VariationData> variationList = [];

  Product? selectedCustomer;

  List<Product> selectedProducts = [];
  Map<int, int> productQty = {};

  // Duration lists for Warranty
  List<String> durationList = ['Days', 'Months', 'Years'];
  List<String> guaranteeList = ['Days', 'Months', 'Years'];

  void calculateMarginForCombo(String saleValue) {
    // ... [Keep existing logic] ...
    final double sale = double.tryParse(saleValue) ?? 0;
    final double purchase = double.tryParse(comboSalePriceController.text) ?? 0;
    if (purchase == 0) {
      comboProfitMarginController.text = '';
      return;
    }
    final margin = ((sale - purchase) / purchase) * 100;
    comboProfitMarginController.text = margin.toStringAsFixed(2);
  }

  void calculatePurchaseAndMrp({String? from}) {
    // ... [Keep existing logic] ...
    num taxRate = selectedTax?.rate ?? 0;
    num purchaseExc = 0;
    num purchaseInc = 0;
    num profitMargin = num.tryParse(profitMarginController.text) ?? 0;
    num salePrice = 0;

    if (from == 'purchase_inc') {
      if (taxRate != 0) {
        purchaseExc = (num.tryParse(purchaseInclusivePriceController.text) ?? 0) / (1 + taxRate / 100);
      } else {
        purchaseExc = num.tryParse(purchaseInclusivePriceController.text) ?? 0;
      }
      purchaseExclusivePriceController.text = purchaseExc.toStringAsFixed(2);
    } else {
      purchaseExc = num.tryParse(purchaseExclusivePriceController.text) ?? 0;
      purchaseInc = purchaseExc + (purchaseExc * taxRate / 100);
      purchaseInclusivePriceController.text = purchaseInc.toStringAsFixed(2);
    }

    purchaseInc = num.tryParse(purchaseInclusivePriceController.text) ?? 0;

    if (from == 'mrp') {
      salePrice = num.tryParse(salePriceController.text) ?? 0;
      num basePrice = selectedTaxType.toLowerCase() == 'exclusive' ? purchaseExc : purchaseInc;

      if (basePrice > 0) {
        profitMargin = ((salePrice - basePrice) / basePrice) * 100;
        profitMarginController.text = profitMargin.toStringAsFixed(2);
      } else {
        profitMarginController.text = '0.00';
      }
    } else {
      num basePrice = selectedTaxType.toLowerCase() == 'exclusive' ? purchaseExc : purchaseInc;

      if (basePrice > 0) {
        salePrice = basePrice + (basePrice * profitMargin / 100);
        salePriceController.text = salePrice.toStringAsFixed(2);
      } else {
        salePriceController.text = '0.00';
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initializeControllers();
    if (widget.productModel == null) {
      _fetchAndSetProductCode();
    }

    productCodeController.addListener(() {
      if (_selectedType == ProductType.single) {
        String code = productCodeController.text;
        if (code.isNotEmpty) {
          batchNumberController.text = "$code-1";
        } else {
          batchNumberController.text = "";
        }
      } else if (_selectedType == ProductType.variant) {
        setState(() {});
      }
    });
  }

  Future<void> _fetchAndSetProductCode() async {
    ProductRepo repo = ProductRepo();
    String? code = await repo.generateProductCode(); // API call

    if (code != null && mounted) {
      setState(() {
        productCodeController.text = code;
      });
    }
  }

  GlobalKey<FormState> key = GlobalKey();
  bool isAlreadyBuild = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ProductType _selectedType = ProductType.single;

  // Changed: No longer instantiating CreateProductModelOld
  // CreateProductModel productData = CreateProductModel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingData = ref.watch(fetchSettingProvider);
    final permissionService = PermissionService(ref);

    return GlobalPopup(
      child: settingData.when(
        data: (snapShot) {
          final showSingle = snapShot.data?.modules?.showProductTypeSingle == '1';
          final showVariant = snapShot.data?.modules?.showProductTypeVariant == '1';
          final showCombo = snapShot.data?.modules?.showProductTypeCombo == '1';

          final List<ProductType> availableTypes = [
            if (showSingle) ProductType.single,
            if (showVariant) ProductType.variant,
            if (showCombo) ProductType.combo,
          ];

          if (availableTypes.isEmpty) {
            availableTypes.add(ProductType.single);
          }

          if (!availableTypes.contains(_selectedType)) {
            _selectedType = availableTypes.first; // NOT forced to Single, but first valid option
          }
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: kWhite,
            appBar: AppBar(
              // ... [Keep existing AppBar] ...
              surfaceTintColor: kWhite,
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black),
              title: Text(
                  widget.productModel != null ? lang.S.of(context).updateProduct : lang.S.of(context).addNewProduct),
              centerTitle: true,
              actions: [
                IconButton(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  icon: Icon(FeatherIcons.settings, color: Color(0xff4B5563)),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  tooltip: lang.S.of(context).openSetting,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1.0),
                child: Divider(height: 1, thickness: 1, color: kBottomBorder),
              ),
            ),
            endDrawer:
                ProductSettingsDrawer(onSave: () => Navigator.of(context).pop(), modules: snapShot.data?.modules),
            body: Consumer(
              builder: (context, ref, __) {
                final taxesData = ref.watch(taxProvider);
                final rackData = ref.watch(rackListProvider);
                final productsList = ref.watch(productProvider);
                final warehouseData = ref.watch(fetchWarehouseListProvider);

                // --- INITIALIZE DROPDOWN SELECTIONS ---

                // 1. VAT / Tax Selection
                taxesData.whenData((dataList) {
                  if (widget.productModel != null && selectedTax == null) {
                    final targetTax = dataList.firstWhereOrNull((vat) => vat.id == widget.productModel?.vatId);
                    if (targetTax != null) {
                      selectedTax = targetTax;
                      Future.microtask(() => setState(() {}));
                    }
                  }
                });

                // 2. RACK/SHELF Selection
                rackData.whenData((rackListModel) {
                  if (widget.productModel != null && selectedRack == null && rackListModel.data != null) {
                    final targetRack = rackListModel.data!.firstWhereOrNull((r) => r.id == widget.productModel?.rackId);
                    if (targetRack != null) {
                      selectedRack = targetRack;
                      // Find the specific Shelf within the selected Rack
                      selectedShelf =
                          selectedRack!.shelves?.firstWhereOrNull((s) => s.id == widget.productModel?.shelfId);
                      Future.microtask(() => setState(() {}));
                    }
                  }
                });

                // 3. WAREHOUSE Selection
                warehouseData.whenData((warehouseListModel) {
                  if (widget.productModel != null && selectedWarehouse == null && warehouseListModel.data != null) {
                    // Assuming productModel.stocks.first.warehouse_id holds the warehouse ID for single product
                    final warehouseId = widget.productModel!.stocks?.firstOrNull?.warehouseId;
                    final targetWarehouse = warehouseListModel.data!.firstWhereOrNull((w) => w.id == warehouseId);
                    if (targetWarehouse != null) {
                      selectedWarehouse = targetWarehouse;
                      Future.microtask(() => setState(() {}));
                    }
                  }
                });

                // --- END INITIALIZE DROPDOWN SELECTIONS ---

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Form(
                      key: key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ... [Keep Image Upload Section] ...
                          if (snapShot.data?.modules?.showProductImage == '1') ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang.S.of(context).image,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: kTitleColor, fontWeight: FontWeight.w500, fontSize: 16)),
                                SizedBox(height: 10),
                                pickedImage == null && previousProductImage == null
                                    ? InkWell(
                                        onTap: () => uploadImageDialog(context, theme),
                                        child: CustomDottedBorder(
                                            color: const Color(0xFFB7B7B7),
                                            borderType: BorderType.rRect,
                                            radius: const Radius.circular(8),
                                            padding: const EdgeInsets.all(6),
                                            child: ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                                child: SizedBox(
                                                    height: 70,
                                                    width: 70,
                                                    child:
                                                        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                      const Icon(IconlyLight.camera, color: kNeutralColor),
                                                      Text(lang.S.of(context).upload,
                                                          style: theme.textTheme.bodyMedium?.copyWith(
                                                              color: kNeutralColor,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500))
                                                    ])))),
                                      )
                                    : GestureDetector(
                                        onTap: () => uploadImageDialog(context, theme),
                                        child: Stack(alignment: Alignment.topRight, children: [
                                          Container(
                                              height: 70,
                                              width: 70,
                                              padding: EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                                  border: Border.all(color: kBorderColorTextField)),
                                              child: Container(
                                                  height: 70,
                                                  width: 70,
                                                  decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                          image: pickedImage != null
                                                              ? FileImage(File(pickedImage!.path))
                                                              : NetworkImage("${APIConfig.domain}$previousProductImage")
                                                                  as ImageProvider,
                                                          fit: BoxFit.cover)))),
                                          Padding(
                                              padding: const EdgeInsets.all(5.0),
                                              child: GestureDetector(
                                                  onTap: () => setState(() {
                                                        previousProductImage = null;
                                                        pickedImage = null;
                                                      }),
                                                  child: const Icon(Icons.close, color: kMainColor, size: 18)))
                                        ]),
                                      ),
                              ],
                            ),
                            SizedBox(height: 24),
                          ],

                          ///____Name & Code & basic fields_____________________________
                          _buildTextField(
                              controller: nameController,
                              label: lang.S.of(context).productName,
                              hint: lang.S.of(context).enterProductName,
                              validator: (value) =>
                                  value!.isEmpty ? lang.S.of(context).pleaseEnterAValidProductName : null),

                          if (snapShot.data?.modules?.showProductCode == '1') ...[
                            SizedBox(height: 24),
                            TextFormField(
                              controller: productCodeController,
                              onFieldSubmitted: (value) {
                                if (codeList.contains(value)) {
                                  EasyLoading.showError(lang.S.of(context).thisProductAlreadyAdded);
                                  productCodeController.clear();
                                }
                              },
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).sku,
                                hintText: lang.S.of(context).enterProductCode,
                                border: const OutlineInputBorder(),
                                suffixIcon: InkWell(
                                    onTap: () => showDialog(
                                        context: context,
                                        builder: (c) => BarcodeScannerWidget(
                                            onBarcodeFound: (code) => productCodeController.text = code)),
                                    child: Container(
                                        padding: EdgeInsets.all(8),
                                        height: 48,
                                        width: 44,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                                            color: Color(0xffD8D8D8).withValues(alpha: 0.3)),
                                        child: SvgPicture.asset(height: 28, 'assets/qr_new.svg'))),
                              ),
                            ),
                          ],

                          ///_______Category & Brand________________________________
                          if ((snapShot.data?.modules?.showProductCategory == '1') ||
                              (snapShot.data?.modules?.showProductBrand == '1'))
                            SizedBox(height: 24),
                          Row(
                            children: [
                              if (snapShot.data?.modules?.showProductCategory == '1')
                                Expanded(
                                    child: TextFormField(
                                        readOnly: true,
                                        controller: categoryController,
                                        onTap: () async {
                                          selectedCategory =
                                              await const CategoryList(isFromProductList: false).launch(context);
                                          setState(
                                              () => categoryController.text = selectedCategory?.categoryName ?? '');
                                        },
                                        decoration: kInputDecoration.copyWith(
                                            suffixIcon: Icon(Icons.keyboard_arrow_down),
                                            floatingLabelBehavior: FloatingLabelBehavior.always,
                                            labelText: lang.S.of(context).category,
                                            hintText: lang.S.of(context).selectProductCategory,
                                            border: const OutlineInputBorder()))),
                              if ((snapShot.data?.modules?.showProductCategory == '1') &&
                                  (snapShot.data?.modules?.showProductBrand == '1'))
                                const SizedBox(width: 14),
                              if (snapShot.data?.modules?.showProductBrand == '1')
                                Expanded(
                                    child: TextFormField(
                                        readOnly: true,
                                        controller: brandController,
                                        onTap: () async {
                                          selectedBrand =
                                              await const BrandsList(isFromProductList: false).launch(context);
                                          setState(() => brandController.text = selectedBrand?.brandName ?? '');
                                        },
                                        decoration: kInputDecoration.copyWith(
                                            suffixIcon: Icon(Icons.keyboard_arrow_down),
                                            floatingLabelBehavior: FloatingLabelBehavior.always,
                                            labelText: lang.S.of(context).brand,
                                            hintText: lang.S.of(context).selectABrand,
                                            border: const OutlineInputBorder()))),
                            ],
                          ),

                          ///_______Rack & Shelf________________________________
                          if ((snapShot.data?.modules?.showRack == '1') || (snapShot.data?.modules?.showShelf == '1'))
                            SizedBox(height: 24),
                          Row(children: [
                            if (snapShot.data?.modules?.showRack == '1')
                              Expanded(
                                  child: rackData.when(
                                      data: (d) => DropdownButtonFormField<RackData>(
                                          isExpanded: true,
                                          hint: Text(lang.S.of(context).selectRack),
                                          decoration: kInputDecoration.copyWith(
                                              labelText: lang.S.of(context).rack, border: OutlineInputBorder()),
                                          value: selectedRack,
                                          items: d.data
                                              ?.map((e) => DropdownMenuItem(value: e, child: Text(e.name ?? '')))
                                              .toList(),
                                          onChanged: (v) => setState(() {
                                                selectedRack = v;
                                                selectedShelf = null; // IMPORTANT: Reset shelf when rack changes
                                              })),
                                      error: (e, s) => Text('Error'),
                                      loading: () => kLoader)),
                            if ((snapShot.data?.modules?.showRack == '1') && (snapShot.data?.modules?.showShelf == '1'))
                              const SizedBox(width: 14),
                            if (snapShot.data?.modules?.showShelf == '1')
                              Expanded(
                                  child: DropdownButtonFormField<Shelf>(
                                isExpanded: true,
                                // Changed type to Shelf
                                hint: Text(lang.S.of(context).selectShelf),
                                decoration: kInputDecoration.copyWith(
                                    labelText: lang.S.of(context).shelf, border: OutlineInputBorder()),
                                value: selectedShelf,
                                // Use the shelves list from the currently selected Rack
                                items: selectedRack?.shelves
                                        ?.map((e) => DropdownMenuItem(value: e, child: Text(e.name ?? '')))
                                        .toList() ??
                                    [],
                                // Disable if no rack is selected
                                onChanged: selectedRack == null ? null : (v) => setState(() => selectedShelf = v),
                              )),
                          ]),

                          ///_______Model & Unit__________________________________
                          if ((snapShot.data?.modules?.showModelNo == '1') ||
                              (snapShot.data?.modules?.showProductUnit == '1'))
                            SizedBox(height: 24),
                          Row(children: [
                            if (snapShot.data?.modules?.showModelNo == '1')
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  controller: modelController,
                                  onTap: () async {
                                    selectedModel =
                                        await const ProductModelList(fromProductList: false).launch(context);
                                    setState(() => modelController.text = selectedModel?.name ?? '');
                                  },
                                  decoration: kInputDecoration.copyWith(
                                    suffixIcon: Icon(Icons.keyboard_arrow_down),
                                    labelText: lang.S.of(context).model,
                                    hintText: lang.S.of(context).selectModel,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            if ((snapShot.data?.modules?.showModelNo == '1') &&
                                (snapShot.data?.modules?.showProductUnit == '1'))
                              const SizedBox(width: 14),
                            if (snapShot.data?.modules?.showProductUnit == '1')
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  controller: productUnitController,
                                  onTap: () async {
                                    selectedUnit = await const UnitList(isFromProductList: false).launch(context);
                                    setState(() => productUnitController.text = selectedUnit?.unitName ?? '');
                                  },
                                  decoration: kInputDecoration.copyWith(
                                    suffixIcon: Icon(Icons.keyboard_arrow_down),
                                    labelText: lang.S.of(context).addUnit,
                                    hintText: lang.S.of(context).selectProductUnit,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                          ]),

                          ///_____________Stock Alert__________________________
                          if (snapShot.data?.modules?.showAlertQty == '1') ...[
                            SizedBox(height: 24),
                            TextFormField(
                              controller: stockAlertController,
                              keyboardType: TextInputType.number,
                              decoration: kInputDecoration.copyWith(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).lowStock,
                                hintText: lang.S.of(context).enLowStock,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],

                          ///--------------Product Type------------------------
                          SizedBox(height: 24),
                          DropdownButtonFormField<ProductType>(
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).select,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              fillColor:
                                  widget.productModel != null ? kGreyTextColor.withOpacity(0.1) : Colors.transparent,
                              filled: widget.productModel != null,
                            ),
                            initialValue: _selectedType,
                            items: [
                              if (showSingle)
                                DropdownMenuItem(
                                  value: ProductType.single,
                                  child: Text(lang.S.of(context).single),
                                ),
                              if (showVariant)
                                DropdownMenuItem(
                                  value: ProductType.variant,
                                  child: Text(lang.S.of(context).variations),
                                ),
                              if (showCombo)
                                DropdownMenuItem(
                                  value: ProductType.combo,
                                  child: Text(lang.S.of(context).combo),
                                ),
                            ],
                            onChanged:
                                widget.productModel != null ? null : (value) => setState(() => _selectedType = value!),
                          ),

                          ///-----------Applicable tax and Type-----------------------------
                          if (snapShot.data?.modules?.showVatType == '1' ||
                              snapShot.data?.modules?.showVatId == '1') ...[
                            SizedBox(height: 20),
                            Row(children: [
                              if (snapShot.data?.modules?.showVatType == '1')
                                Expanded(
                                    child: DropdownButtonFormField<String?>(
                                        isExpanded: true,
                                        hint: Text(lang.S.of(context).typeSelect),
                                        decoration: kInputDecoration.copyWith(labelText: lang.S.of(context).taxType),
                                        value: selectedTaxType,
                                        items: ["inclusive", "exclusive"]
                                            .map((type) => DropdownMenuItem<String?>(value: type, child: Text(type)))
                                            .toList(),
                                        onChanged: (value) {
                                          selectedTaxType = value!;
                                          calculatePurchaseAndMrp();
                                        })),
                              if (snapShot.data?.modules?.showVatType == '1' &&
                                  snapShot.data?.modules?.showVatId == '1')
                                const SizedBox(width: 14),
                              if (snapShot.data?.modules?.showVatId == '1')
                                Expanded(
                                  child: taxesData.when(
                                    data: (dataList) => DropdownButtonFormField<VatModel>(
                                      isExpanded: true,
                                      hint: Text(lang.S.of(context).selectTax),
                                      decoration: kInputDecoration.copyWith(
                                        labelText: lang.S.of(context).selectTax,
                                      ),
                                      initialValue: selectedTax,
                                      icon: selectedTax != null
                                          ? IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.clear,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                selectedTax = null;
                                                calculatePurchaseAndMrp();
                                              },
                                            )
                                          : null,
                                      items: dataList
                                          .where((vat) => vat.status == true)
                                          .map(
                                            (vat) => DropdownMenuItem<VatModel>(
                                              value: vat,
                                              child: Text('${vat.name ?? ''} ${vat.rate}%'),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        selectedTax = value;
                                        calculatePurchaseAndMrp();
                                      },
                                    ),
                                    error: (e, s) => const Text('Error'),
                                    loading: () => kLoader,
                                  ),
                                ),
                            ]),
                          ],

                          ///------------Single Product Form------------------------------------
                          if (_selectedType == ProductType.single)
                            SingleProductForm(
                              snapShot: snapShot,
                              // Controllers
                              batchController: batchNumberController,
                              stockController:
                                  productStockController, // Using stockAlertController for quantity as per your logic (or check if it should be productStockController)
                              purchaseExController: purchaseExclusivePriceController,
                              purchaseIncController: purchaseInclusivePriceController,
                              profitController: profitMarginController,
                              saleController: salePriceController,
                              wholesaleController: wholeSalePriceController,
                              dealerController: dealerPriceController,
                              mfgDateController: manufactureDateController,
                              expDateController: expireDateController,
                              // State & Callbacks
                              selectedWarehouse: selectedWarehouse,
                              onWarehouseChanged: (val) => setState(() => selectedWarehouse = val),
                              onPriceChanged: (from) => calculatePurchaseAndMrp(from: from),
                              onMfgDateSelected: (dateString) => setState(() {
                                manufactureDateController.text = DateFormat.yMd().format(DateTime.parse(dateString));
                                selectedManufactureDate = dateString;
                              }),
                              onExpDateSelected: (dateString) => setState(() {
                                expireDateController.text = DateFormat.yMd().format(DateTime.parse(dateString));
                                selectedExpireDate = dateString;
                              }),
                            ),

                          ///--------- Variations Product Form ---------------------------
                          if (_selectedType == ProductType.variant)
                            VariantProductForm(
                              initialStocks: variantStocks,
                              snapShot: snapShot,
                              tax: selectedTax,
                              selectedWarehouse: selectedWarehouse,
                              productCode: productCodeController.text,
                              taxType: selectedTaxType,
                              productVariationIds: widget.productModel?.variationIds,
                              onStocksUpdated: (updatedStocks) {
                                setState(() {
                                  variantStocks = updatedStocks;
                                });
                              },
                              onSelectVariation: (ids) {
                                variationIds = ids;
                              },
                            ),

                          ///--------- COMBO Product Form ---------------------------
                          if (_selectedType == ProductType.combo) ...[
                            SizedBox(height: 13),
                            ComboProductForm(
                              // 1. Passing Controllers from Parent
                              profitController: comboProfitMarginController,
                              saleController: comboSalePriceController,
                              purchasePriceController: purchaseExclusivePriceController,

                              // 2. Edit Data Pass
                              initialComboList: comboList,

                              // 3. List Callback
                              onComboListChanged: (List<ComboProductModel> items) {
                                comboList = items;

                                purchaseInclusivePriceController.text = purchaseExclusivePriceController.text;
                              },
                            ),
                          ],

                          ///-----------------Warranty-&-Guarantee-------------
                          // if (_selectedType != ProductType.variant) SizedBox(height: 24),

                          if ((snapShot.data?.modules?.showWarranty == '1') ||
                              (snapShot.data?.modules?.showGuaranty == '1')) ...[
                            Column(
                              children: [
                                Row(spacing: 10, children: [
                                  if (snapShot.data?.modules?.showWarranty == '1')
                                    Expanded(
                                        child: TextFormField(
                                            controller: warrantyController,
                                            decoration: kInputDecoration.copyWith(
                                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                                labelText: lang.S.of(context).warranty,
                                                hintText: 'Ex 30',
                                                border: const OutlineInputBorder(),
                                                suffixIcon: _buildDurationDropdown()))),
                                  if (snapShot.data?.modules?.showGuaranty == '1')
                                    Expanded(
                                        child: TextFormField(
                                            controller: guaranteeController,
                                            decoration: kInputDecoration.copyWith(
                                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                                labelText: lang.S.of(context).guarantee,
                                                hintText: 'Ex 30',
                                                border: const OutlineInputBorder(),
                                                suffixIcon: _buildGuaranteeDropdown()))),
                                ]),
                                SizedBox(height: 24),
                              ],
                            ),
                          ],

                          ElevatedButton(
                            onPressed: () async {
                              print('${selectedVariation.map((e) => e.toString()).toList()}');
                              if ((key.currentState?.validate() ?? false)) {
                                ProductRepo productRepo = ProductRepo();
                                bool success;

                                // 1. Prepare Stocks List based on Type
                                List<StockDataModel> finalStocks = [];

                                if (_selectedType == ProductType.single) {
                                  // Create a single stock entry from the Single Product Form controllers
                                  finalStocks.add(StockDataModel(
                                    stockId: widget.productModel?.stocks?.firstOrNull?.id
                                        .toString(), // Preserve ID if updating

                                    warehouseId: selectedWarehouse?.id.toString(),
                                    // Using stockAlertController as per your UI logic for stock quantity
                                    productStock: productStockController.text,
                                    exclusivePrice: purchaseExclusivePriceController.text,
                                    inclusivePrice: purchaseInclusivePriceController.text,
                                    profitPercent: profitMarginController.text,
                                    productSalePrice: salePriceController.text,
                                    productWholeSalePrice: wholeSalePriceController.text,
                                    productDealerPrice: dealerPriceController.text,
                                    mfgDate: selectedManufactureDate,
                                    expireDate: selectedExpireDate,
                                  ));
                                } else if (_selectedType == ProductType.variant) {
                                  if (variantStocks.isEmpty) {
                                    EasyLoading.showError("Please generate variations");
                                    return;
                                  }
                                  finalStocks = variantStocks;
                                }
                                print('Variation ids $variationIds');
                                // 2. Construct the NEW Model
                                CreateProductModel submitData = CreateProductModel(
                                  productId: widget.productModel?.id.toString(),
                                  name: nameController.text,
                                  categoryId: selectedCategory?.id.toString(),
                                  brandId: selectedBrand?.id.toString(),
                                  unitId: selectedUnit?.id.toString(),
                                  modelId: selectedModel?.id.toString(),
                                  productCode: productCodeController.text,
                                  alertQty: stockAlertController.text,
                                  rackId: selectedRack?.id.toString(),
                                  shelfId: selectedShelf?.id.toString(),
                                  productType: _selectedType.name,
                                  vatType: selectedTaxType,
                                  vatId: selectedTax?.id.toString(),
                                  vatAmount: ((num.tryParse(purchaseInclusivePriceController.text) ?? 0) -
                                          (num.tryParse(purchaseExclusivePriceController.text) ?? 0))
                                      .toString(),

                                  // New structure: Pass the list of StockDataModel
                                  stocks: finalStocks,

                                  // Variant IDs (only needed for variant type)
                                  variationIds: _selectedType == ProductType.variant ? variationIds : null,

                                  // Extra Fields
                                  productManufacturer: manufacturerController.text,
                                  productDiscount: discountPriceController.text,
                                  image: pickedImage != null ? File(pickedImage!.path) : null,

                                  // Warranty
                                  warrantyDuration: warrantyController.text,
                                  warrantyPeriod: selectedTimeWarranty,
                                  guaranteeDuration: guaranteeController.text,
                                  guaranteePeriod: selectedTimeGuarantee,
                                );
                                // --- TYPE: COMBO ---
                                if (_selectedType == ProductType.combo) {
                                  if (comboList.isEmpty) {
                                    EasyLoading.showError("Please add products to combo");
                                    return;
                                  }
                                  submitData.comboProducts = comboList;
                                  submitData.comboProfitPercent = comboProfitMarginController.text;
                                  submitData.comboProductSalePrice = comboSalePriceController.text;
                                }

                                // 3. Call API
                                if (widget.productModel != null) {
                                  if (!permissionService.hasPermission(Permit.productsUpdate.value)) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(lang.S.of(context).updateProductWarn)));
                                    return;
                                  }
                                  success =
                                      await productRepo.updateProduct(data: submitData, ref: ref, context: context);
                                } else {
                                  if (!permissionService.hasPermission(Permit.productsCreate.value)) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        backgroundColor: Colors.red, content: Text(lang.S.of(context).addProductWarn)));
                                    return;
                                  }
                                  success =
                                      await productRepo.createProduct(data: submitData, ref: ref, context: context);
                                }

                                if (success) {
                                  if (widget.productModel != null) {
                                    ref.refresh(fetchProductDetails(widget.productModel?.id.toString() ?? ''));
                                  }
                                  ref.refresh(productProvider);
                                  Navigator.pop(context);
                                }
                              }
                            },
                            child: Text(widget.productModel != null
                                ? lang.S.of(context).update
                                : lang.S.of(context).saveNPublish),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        error: (e, stack) {
          return Text(e.toString());
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: kGreyTextColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                icon: Icon(Icons.keyboard_arrow_down),
                value: selectedTimeWarranty != null && durationList.contains(selectedTimeWarranty)
                    ? selectedTimeWarranty
                    : null,
                items: [
                  // 'Days', 'Months', 'Years'
                  DropdownMenuItem(value: 'Days', child: Text(lang.S.of(context).days)),
                  DropdownMenuItem(value: 'Months', child: Text(lang.S.of(context).month)),
                  DropdownMenuItem(value: 'Years', child: Text(lang.S.of(context).years)),
                ],
                onChanged: (v) => setState(() => selectedTimeWarranty = v),
                hint: Text(lang.S.of(context).select))));
  }

  Widget _buildGuaranteeDropdown() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: kGreyTextColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                icon: Icon(Icons.keyboard_arrow_down),
                value: selectedTimeGuarantee != null && guaranteeList.contains(selectedTimeGuarantee)
                    ? selectedTimeGuarantee
                    : null,
                items: [
                  // 'Days', 'Months', 'Years'
                  DropdownMenuItem(value: 'Days', child: Text(lang.S.of(context).days)),
                  DropdownMenuItem(value: 'Months', child: Text(lang.S.of(context).month)),
                  DropdownMenuItem(value: 'Years', child: Text(lang.S.of(context).years)),
                ],
                // items: guaranteeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => selectedTimeGuarantee = v),
                hint: Text(lang.S.of(context).select))));
  }

  Future<dynamic> uploadImageDialog(BuildContext context, ThemeData theme) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.clear, color: kNeutral800))),
                Text(lang.S.of(context).choose,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: kTitleColor, fontWeight: FontWeight.w400, fontSize: 18)),
                SizedBox(height: 30),
                Center(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  GestureDetector(
                      onTap: () async {
                        pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                        setState(() {});
                        Future.delayed(const Duration(milliseconds: 100), () => Navigator.pop(context));
                      },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.photo_library_outlined, size: 40.0, color: kMainColor),
                        Text(lang.S.of(context).gallery,
                            style: theme.textTheme.titleMedium?.copyWith(color: kMainColor))
                      ])),
                  const SizedBox(width: 50.0),
                  GestureDetector(
                      onTap: () async {
                        pickedImage = await _picker.pickImage(source: ImageSource.camera);
                        setState(() {});
                        Future.delayed(const Duration(milliseconds: 100), () => Navigator.pop(context));
                      },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.camera_alt_outlined, size: 40.0, color: kGreyTextColor),
                        Text(lang.S.of(context).camera,
                            style: theme.textTheme.titleMedium?.copyWith(color: kGreyTextColor))
                      ])),
                ])),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  bool readOnly = false,
  bool? icon,
  VoidCallback? onTap,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    validator: validator,
    keyboardType: keyboardType,
    decoration: kInputDecoration.copyWith(
      labelText: label,
      hintText: hint,
      suffixIcon: (icon ?? false) ? const Icon(Icons.keyboard_arrow_down_outlined) : null,
      border: const OutlineInputBorder(),
    ),
  );
}

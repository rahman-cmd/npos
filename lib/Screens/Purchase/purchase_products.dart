import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/Screens/Purchase/Repo/purchase_repo.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/add_to_cart_purchase.dart';

class PurchaseProducts extends StatefulWidget {
  PurchaseProducts({super.key, this.customerModel});

  Party? customerModel;

  @override
  State<PurchaseProducts> createState() => _PurchaseProductsState();
}

class _PurchaseProductsState extends State<PurchaseProducts> {
  String productCode = '0000';
  TextEditingController codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(cartNotifierPurchaseNew);
      final productList = ref.watch(productProvider);
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(
              lang.S.of(context).productList,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: AppTextField(
                            controller: codeController,
                            textFieldType: TextFieldType.NAME,
                            onChanged: (value) {
                              setState(() {
                                productCode = value;
                              });
                            },
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText: lang.S.of(context).productCode,
                              hintText: productCode == '0000' || productCode == '-1' ? 'Scan product QR code' : productCode,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: GestureDetector(
                            onTap: () async {
                              await showDialog(
                                context: context,
                                useSafeArea: true,
                                builder: (context1) {
                                  MobileScannerController controller = MobileScannerController(
                                    torchEnabled: false,
                                    returnImage: false,
                                  );
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadiusDirectional.circular(6.0),
                                    ),
                                    child: Column(
                                      children: [
                                        AppBar(
                                          backgroundColor: Colors.transparent,
                                          iconTheme: const IconThemeData(color: Colors.white),
                                          leading: IconButton(
                                            icon: const Icon(Icons.arrow_back),
                                            onPressed: () {
                                              Navigator.pop(context1);
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: MobileScanner(
                                            fit: BoxFit.contain,
                                            controller: controller,
                                            onDetect: (capture) {
                                              final List<Barcode> barcodes = capture.barcodes;

                                              if (barcodes.isNotEmpty) {
                                                final Barcode barcode = barcodes.first;
                                                debugPrint('Barcode found! ${barcode.rawValue}');

                                                setState(() {
                                                  productCode = barcode.rawValue!;
                                                  codeController.text = productCode;
                                                });

                                                Navigator.pop(context1);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 60.0,
                              width: 100.0,
                              padding: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: kGreyTextColor),
                              ),
                              child: const Image(
                                image: AssetImage('images/barcode.png'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  productList.when(data: (products) {
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (_) {
                                    final cartProduct = CartProductModelPurchase(
                                      productId: products[i].id ?? 0,
                                      brandName: products[i].brand?.brandName ?? '',
                                      productName: products[i].productName ?? '',
                                      productDealerPrice: products[i].productDealerPrice,
                                      productPurchasePrice: products[i].productPurchasePrice,
                                      productSalePrice: products[i].productSalePrice,
                                      productWholeSalePrice: products[i].productWholeSalePrice,
                                      quantities: 1,
                                      stock: products[i].productStock,
                                    );

                                    return purchaseProductAddBottomSheet(context: context, product: cartProduct, ref: ref, fromUpdate: false);
                                    // return AlertDialog(
                                    //     content: SizedBox(
                                    //   child: SingleChildScrollView(
                                    //     child: Column(
                                    //       mainAxisSize: MainAxisSize.min,
                                    //       children: [
                                    //         Padding(
                                    //           padding: const EdgeInsets.only(bottom: 10),
                                    //           child: Row(
                                    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //             children: [
                                    //               Text(
                                    //                 lang.S.of(context).addItems,
                                    //                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    //               ),
                                    //               GestureDetector(
                                    //                   onTap: () {
                                    //                     Navigator.pop(context);
                                    //                   },
                                    //                   child: const Icon(
                                    //                     Icons.cancel,
                                    //                     color: kMainColor,
                                    //                   )),
                                    //             ],
                                    //           ),
                                    //         ),
                                    //         Container(
                                    //           height: 1,
                                    //           width: double.infinity,
                                    //           color: Colors.grey,
                                    //         ),
                                    //         const SizedBox(height: 10),
                                    //         Row(
                                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //           children: [
                                    //             Column(
                                    //               mainAxisSize: MainAxisSize.min,
                                    //               crossAxisAlignment: CrossAxisAlignment.start,
                                    //               children: [
                                    //                 Text(
                                    //                   products[i].productName.toString(),
                                    //                   style: const TextStyle(fontSize: 16),
                                    //                 ),
                                    //                 Text(
                                    //                   products[i].brand?.brandName ?? '',
                                    //                   style: const TextStyle(
                                    //                     fontSize: 16,
                                    //                     color: Colors.grey,
                                    //                   ),
                                    //                 ),
                                    //               ],
                                    //             ),
                                    //             Column(
                                    //               mainAxisSize: MainAxisSize.min,
                                    //               crossAxisAlignment: CrossAxisAlignment.end,
                                    //               children: [
                                    //                 Text(
                                    //                   lang.S.of(context).stock,
                                    //                   style: const TextStyle(fontSize: 16),
                                    //                 ),
                                    //                 Text(
                                    //                   products[i].productStock.toString(),
                                    //                   style: const TextStyle(
                                    //                     fontSize: 16,
                                    //                     color: Colors.grey,
                                    //                   ),
                                    //                 ),
                                    //               ],
                                    //             ),
                                    //           ],
                                    //         ),
                                    //         const SizedBox(height: 20),
                                    //         Row(
                                    //           mainAxisSize: MainAxisSize.min,
                                    //           children: [
                                    //             Expanded(
                                    //               child: AppTextField(
                                    //                 textFieldType: TextFieldType.NUMBER,
                                    //                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    //                 onChanged: (value) {
                                    //                   tempProduct.productStock = num.tryParse(value);
                                    //                 },
                                    //                 decoration: InputDecoration(
                                    //                   floatingLabelBehavior: FloatingLabelBehavior.always,
                                    //                   labelText: lang.S.of(context).quantity,
                                    //                   // hintText: 'Enter quantity',
                                    //                   hintText: lang.S.of(context).enterQuantity,
                                    //                   border: const OutlineInputBorder(),
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //         const SizedBox(height: 20),
                                    //         Row(
                                    //           mainAxisSize: MainAxisSize.min,
                                    //           children: [
                                    //             Expanded(
                                    //               child: TextFormField(
                                    //                 initialValue: products[i].productPurchasePrice.toString(),
                                    //                 keyboardType: TextInputType.number,
                                    //                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    //                 onChanged: (value) {
                                    //                   tempProduct.productPurchasePrice = num.tryParse(value);
                                    //                 },
                                    //                 decoration: InputDecoration(
                                    //                   floatingLabelBehavior: FloatingLabelBehavior.always,
                                    //                   labelText: lang.S.of(context).purchasePrice,
                                    //                   border: const OutlineInputBorder(),
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //             const SizedBox(width: 10),
                                    //             Expanded(
                                    //               child: TextFormField(
                                    //                 initialValue: products[i].productSalePrice.toString(),
                                    //                 keyboardType: TextInputType.number,
                                    //                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    //                 onChanged: (value) {
                                    //                   tempProduct.productSalePrice = num.tryParse(value);
                                    //                 },
                                    //                 decoration: InputDecoration(
                                    //                   floatingLabelBehavior: FloatingLabelBehavior.always,
                                    //                   labelText: lang.S.of(context).salePrice,
                                    //                   border: const OutlineInputBorder(),
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //         const SizedBox(height: 20),
                                    //         Row(
                                    //           mainAxisSize: MainAxisSize.min,
                                    //           children: [
                                    //             Expanded(
                                    //               child: TextFormField(
                                    //                 initialValue: products[i].productWholeSalePrice.toString(),
                                    //                 keyboardType: TextInputType.number,
                                    //                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    //                 onChanged: (value) {
                                    //                   tempProduct.productWholeSalePrice = num.tryParse(value);
                                    //                 },
                                    //                 decoration: InputDecoration(
                                    //                   floatingLabelBehavior: FloatingLabelBehavior.always,
                                    //                   labelText: lang.S.of(context).wholeSalePrice,
                                    //                   border: const OutlineInputBorder(),
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //             const SizedBox(width: 10),
                                    //             Expanded(
                                    //               child: TextFormField(
                                    //                 initialValue: products[i].productDealerPrice.toString(),
                                    //                 keyboardType: TextInputType.number,
                                    //                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    //                 onChanged: (value) {
                                    //                   tempProduct.productDealerPrice = num.tryParse(value);
                                    //                 },
                                    //                 decoration: InputDecoration(
                                    //                   floatingLabelBehavior: FloatingLabelBehavior.always,
                                    //                   labelText: lang.S.of(context).dealerPrice,
                                    //                   border: const OutlineInputBorder(),
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //         const SizedBox(height: 20),
                                    //         GestureDetector(
                                    //           onTap: () {
                                    //             if ((tempProduct.productStock ?? 0) > 0) {
                                    //               providerData.addToCartRiverPod(
                                    //                   cartItem: CartProducts(
                                    //                 productId: tempProduct.id ?? 0,
                                    //                 productName: tempProduct.productName ?? '',
                                    //                 productDealerPrice: tempProduct.productDealerPrice,
                                    //                 productPurchasePrice: tempProduct.productPurchasePrice,
                                    //                 productSalePrice: tempProduct.productSalePrice,
                                    //                 productWholeSalePrice: tempProduct.productWholeSalePrice,
                                    //                 quantities: tempProduct.productStock,
                                    //               ));
                                    //               ref.refresh(productProvider);
                                    //               int count = 0;
                                    //               Navigator.popUntil(context, (route) {
                                    //                 return count++ == 2;
                                    //               });
                                    //             } else {
                                    //               EasyLoading.showError(
                                    //                 lang.S.of(context).pleaseAddQuantity,
                                    //                 // 'Please add quantity'
                                    //               );
                                    //             }
                                    //           },
                                    //           child: Container(
                                    //             height: 60,
                                    //             width: context.width(),
                                    //             decoration: const BoxDecoration(color: kMainColor, borderRadius: BorderRadius.all(Radius.circular(15))),
                                    //             child: Center(
                                    //               child: Text(
                                    //                 lang.S.of(context).save,
                                    //                 style: const TextStyle(fontSize: 18, color: Colors.white),
                                    //               ),
                                    //             ),
                                    //           ),
                                    //         )
                                    //       ],
                                    //     ),
                                    //   ),
                                    // ));
                                  });
                            },
                            child: ProductCard(
                              productTitle: products[i].productName.toString(),
                              productDescription: products[i].brand?.brandName ?? '',
                              stock: products[i].productStock.toString(),
                              productImage: products[i].productPicture,
                            ).visible(((products[i].productCode == productCode || productCode == '0000' || productCode == '-1')) ||
                                products[i].productName!.toLowerCase().contains(productCode.toLowerCase())),
                          );
                        });
                  }, error: (e, stack) {
                    return Text(e.toString());
                  }, loading: () {
                    return const Center(child: CircularProgressIndicator());
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ignore: must_be_immutable
class ProductCard extends StatefulWidget {
  ProductCard({super.key, required this.productTitle, required this.productDescription, required this.stock, required this.productImage});

  // final Product product;
  String productTitle, productDescription, stock;
  String? productImage;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, __) {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                height: 50,
                width: 50,
                decoration: widget.productImage == null
                    ? BoxDecoration(
                        image: DecorationImage(image: AssetImage(noProductImageUrl), fit: BoxFit.cover),
                        borderRadius: BorderRadius.circular(90.0),
                      )
                    : BoxDecoration(
                        image: DecorationImage(image: NetworkImage("${APIConfig.domain}${widget.productImage}"), fit: BoxFit.cover),
                        borderRadius: BorderRadius.circular(90.0),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.productTitle,
                        style: GoogleFonts.jost(
                          fontSize: 20.0,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.productDescription,
                    style: GoogleFonts.jost(
                      fontSize: 15.0,
                      color: kGreyTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lang.S.of(context).stock,
                  style: GoogleFonts.jost(
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                ),
                Text(
                  widget.stock,
                  style: GoogleFonts.jost(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

purchaseProductAddBottomSheet({required BuildContext context, required CartProductModelPurchase product, required WidgetRef ref, required bool fromUpdate}) {
  CartProductModelPurchase tempProduct = CartProductModelPurchase(
    productDealerPrice: product.productDealerPrice,
    productId: product.productId,
    quantities: product.quantities,
    brandName: product.brandName,
    stock: product.stock,
    productName: product.productName,
    productPurchasePrice: product.productPurchasePrice,
    productSalePrice: product.productSalePrice,
    productWholeSalePrice: product.productWholeSalePrice,
  );
  return AlertDialog(
      content: SizedBox(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.S.of(context).addItems,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.cancel,
                      color: kMainColor,
                    )),
              ],
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    product.brandName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lang.S.of(context).stock,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    product.stock.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: AppTextField(
                  initialValue: product.quantities.toString(),
                  textFieldType: TextFieldType.NUMBER,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  onChanged: (value) {
                    tempProduct.quantities = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).quantity,
                    // hintText: 'Enter quantity',
                    hintText: lang.S.of(context).enterQuantity,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: product.productPurchasePrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  onChanged: (value) {
                    tempProduct.productPurchasePrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).purchasePrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: product.productSalePrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  onChanged: (value) {
                    tempProduct.productSalePrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).salePrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: product.productWholeSalePrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  onChanged: (value) {
                    tempProduct.productWholeSalePrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).wholeSalePrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: product.productDealerPrice.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  onChanged: (value) {
                    tempProduct.productDealerPrice = num.tryParse(value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: lang.S.of(context).dealerPrice,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if ((tempProduct.quantities ?? 0) > 0) {
                ref.watch(cartNotifierPurchaseNew).addToCartRiverPod(
                        cartItem: CartProductModelPurchase(
                      brandName: tempProduct.brandName,
                      stock: tempProduct.stock,
                      productId: tempProduct.productId ,
                      productName: tempProduct.productName ?? '',
                      productDealerPrice: tempProduct.productDealerPrice,
                      productPurchasePrice: tempProduct.productPurchasePrice,
                      productSalePrice: tempProduct.productSalePrice,
                      productWholeSalePrice: tempProduct.productWholeSalePrice,
                      quantities: tempProduct.quantities,
                    ));
                // if (!fromUpdate) {
                //
                // }else{
                //
                // }

                // ref.refresh(productProvider);
                if (fromUpdate) {
                  Navigator.pop(context);
                } else {
                  int count = 0;
                  Navigator.popUntil(context, (route) {
                    return count++ == 2;
                  });
                }
              } else {
                EasyLoading.showError(
                  lang.S.of(context).pleaseAddQuantity,
                  // 'Please add quantity'
                );
              }
            },
            child: Container(
              height: 60,
              width: context.width(),
              decoration: const BoxDecoration(color: kMainColor, borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Center(
                child: Text(
                  lang.S.of(context).save,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    ),
  ));
}

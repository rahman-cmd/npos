import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../Const/api_config.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/add_to_cart.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';

class SaleProductsList extends StatefulWidget {
  const SaleProductsList({super.key, this.customerModel});

  final Party? customerModel;

  @override
  // ignore: library_private_types_in_public_api
  _SaleProductsListState createState() => _SaleProductsListState();
}

class _SaleProductsListState extends State<SaleProductsList> {
  // String dropdownValue = '';
  String productCode = '0000';
  TextEditingController codeController = TextEditingController();
  num productPrice = 0;
  String sentProductPrice = '';

  @override
  void initState() {
    // widget.catName == null ? dropdownValue = 'Fashion' : dropdownValue = widget.catName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Consumer(builder: (context, ref, __) {
        final providerData = ref.watch(cartNotifier);
        final productList = ref.watch(productProvider);

        return Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(
              lang.S.of(context).addItems,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
            // actions: [
            //   PopupMenuButton(
            //     itemBuilder: (BuildContext bc) => [
            //       const PopupMenuItem(value: "/addPromoCode", child: Text('Add Promo Code')),
            //       const PopupMenuItem(value: "clear", child: Text('Cancel All Product')),
            //       const PopupMenuItem(value: "/settings", child: Text('Vat Doesn\'t Apply')),
            //     ],
            //     onSelected: (value) {
            //       value == 'clear'
            //           ? {
            //               providerData.clearCart(),
            //               providerData.clearDiscount(),
            //               const HomeScreen().launch(context, isNewTask: true)
            //             }
            //           : Navigator.pushNamed(context, '$value');
            //     },
            //   ),
            // ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Container(
                  //   height: 60.0,
                  //   width: MediaQuery.of(context).size.width,
                  //   decoration: BoxDecoration(
                  //     color: kMainColor,
                  //     borderRadius: BorderRadius.circular(10.0),
                  //   ),
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       // ignore: missing_required_param
                  //       providerData.getTotalAmount() <= 0
                  //           ? EasyLoading.showError('Cart Is Empty')
                  //           : SalesDetails(
                  //               customerName: widget.customerModel!.customerName,
                  //             ).launch(context);
                  //     },
                  //     child: Row(
                  //       children: [
                  //         Expanded(
                  //           flex: 1,
                  //           child: Stack(
                  //             alignment: Alignment.center,
                  //             children: [
                  //               const Image(
                  //                 image: AssetImage('images/selected.png'),
                  //               ),
                  //               Text(
                  //                 items.toString(),
                  //                 style: GoogleFonts.poppins(
                  //                   fontSize: 15.0,
                  //                   color: Colors.white,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //         Expanded(
                  //           flex: 2,
                  //           child: Center(
                  //             child: Text(
                  //               providerData.getTotalAmount() <= 0
                  //                   ? 'Cart is empty'
                  //                   : 'Total: $currency${providerData.getTotalAmount().toString()}',
                  //               style: GoogleFonts.poppins(
                  //                 color: Colors.white,
                  //                 fontSize: 16.0,
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //         const Expanded(
                  //           flex: 1,
                  //           child: Icon(
                  //             Icons.arrow_forward,
                  //             color: Colors.white,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 20.0),
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
                          if (widget.customerModel != null) {
                            if (widget.customerModel!.type!.contains('Retailer')) {
                              productPrice = products[i].productSalePrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Dealer')) {
                              productPrice = products[i].productDealerPrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Wholesaler')) {
                              productPrice = products[i].productWholeSalePrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Supplier')) {
                              productPrice = products[i].productPurchasePrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Guest')) {
                              productPrice = products[i].productSalePrice ?? 0;
                            }
                          } else {
                            productPrice = products[i].productSalePrice ?? 0;
                          }

                          return GestureDetector(
                            onTap: () async {
                              if ((products[i].productStock ?? 0) <= 0) {
                                EasyLoading.showError('Out of stock');
                              } else {
                                if (widget.customerModel == null) {
                                  sentProductPrice = products[i].productSalePrice.toString();
                                } else {
                                  if (widget.customerModel!.type!.contains('Retailer')) {
                                    sentProductPrice = products[i].productSalePrice.toString();
                                  } else if (widget.customerModel!.type!.contains('Dealer')) {
                                    sentProductPrice = products[i].productDealerPrice.toString();
                                  } else if (widget.customerModel!.type!.contains('Wholesaler')) {
                                    sentProductPrice = products[i].productWholeSalePrice.toString();
                                  } else if (widget.customerModel!.type!.contains('Supplier')) {
                                    sentProductPrice = products[i].productPurchasePrice.toString();
                                  }
                                }

                                AddToCartModel cartItem = AddToCartModel(
                                  productName: products[i].productName,
                                  unitPrice: sentProductPrice,
                                  productCode: products[i].productCode,
                                  // productBrandName: products[i].brand?.brandName ?? '',
                                  productPurchasePrice: products[i].productPurchasePrice,
                                  stock: (products[i].productStock ?? 0).round(),
                                  productId: products[i].id ?? 0,
                                );
                                providerData.addToCartRiverPod(cartItem: cartItem,fromEditSales: false);
                                Navigator.pop(context);
                              }
                            },
                            child: ProductCard(
                              productTitle: products[i].productName.toString(),
                              productDescription: products[i].brand?.brandName ?? '',
                              productPrice: productPrice,
                              productImage: products[i].productPicture,
                              stock: products[i].productStock ?? 0,
                            ).visible((products[i].productCode == productCode || productCode == '0000' || productCode == '-1') && productPrice != '0' ||
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
          // bottomNavigationBar: ButtonGlobal(
          //   iconWidget: Icons.arrow_forward,
          //   buttontext: 'Sales List',
          //   iconColor: Colors.white,
          //   buttonDecoration: kButtonDecoration.copyWith(color: kMainColor),
          //   onPressed: () {
          //     // ignore: missing_required_param
          //     providerData.getTotalAmount() <= 0
          //         ? EasyLoading.showError('Cart Is Empty')
          //         : SalesDetails(
          //             customerName: widget.customerModel!.customerName,
          //           ).launch(context);
          //   },
          // ),
        );
      }),
    );
  }
}

// ignore: must_be_immutable
class ProductCard extends StatefulWidget {
  ProductCard({Key? key, required this.productTitle, required this.productDescription, required this.productPrice, required this.productImage, required this.stock})
      : super(key: key);

  // final Product product;
  String productTitle, productDescription;
  num productPrice, stock;
  String? productImage;
  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(cartNotifier);
      for (var element in providerData.cartItemList) {
        if (element.productName == widget.productTitle) {
          quantity = element.quantity;
        }
      }
      // return Padding(
      //   padding: const EdgeInsets.all(5.0),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       Row(children: [Padding(
      //         padding: const EdgeInsets.all(4.0),
      //         child: Container(
      //           height: 50,
      //           width: 50,
      //           decoration: widget.productImage == null
      //               ? BoxDecoration(
      //             image: DecorationImage(image: AssetImage(noProductImageUrl), fit: BoxFit.cover),
      //             borderRadius: BorderRadius.circular(90.0),
      //           )
      //               : BoxDecoration(
      //             image: DecorationImage(image: NetworkImage("${APIConfig.domain}${widget.productImage}"), fit: BoxFit.cover),
      //             borderRadius: BorderRadius.circular(90.0),
      //           ),
      //         ),
      //       ),
      //         Padding(
      //           padding: const EdgeInsets.only(left: 10.0),
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             mainAxisSize: MainAxisSize.min,
      //             children: [
      //               Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 mainAxisSize: MainAxisSize.min,
      //                 children: [
      //                   Flexible(
      //                     child: Text(
      //                       widget.productTitle,
      //                       style: GoogleFonts.jost(
      //                         fontSize: 20.0,
      //                         color: Colors.black,
      //                       ),
      //                       overflow: TextOverflow.ellipsis,  // Handle overflow with ellipsis
      //                       maxLines: 1,  // Limit the number of lines
      //                     ),
      //                   ),
      //                   Flexible(
      //                     child: Text(
      //                       //'Stock: ${widget.stock}',
      //                       '${lang.S.of(context).stocks}${widget.stock}',
      //                       style: GoogleFonts.jost(
      //                         color: Colors.black,
      //                       ),
      //                       overflow: TextOverflow.ellipsis,  // Handle overflow with ellipsis
      //                       maxLines: 1,  // Limit the number of lines
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //               Flexible(
      //                 child: Text(
      //                   widget.productDescription,
      //                   style: GoogleFonts.jost(
      //                     fontSize: 15.0,
      //                     color: kGreyTextColor,
      //                   ),
      //                   overflow: TextOverflow.ellipsis,  // Handle overflow with ellipsis
      //                   maxLines: 2,  // Limit the number of lines
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),],),
      //       Text(
      //         '$currency${widget.productPrice}',
      //         style: GoogleFonts.jost(
      //           fontSize: 20.0,
      //           color: Colors.black,
      //         ),
      //         overflow: TextOverflow.ellipsis,  // Handle overflow with ellipsis
      //         maxLines: 1,  // Limit the number of lines
      //       ),
      //     ],
      //   ),
      // );

      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
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
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.productTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jost(
                                  fontSize: 20.0,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                //'Stock: ${widget.stock}',
                                '${lang.S.of(context).stocks}${widget.stock}',
                                style: GoogleFonts.jost(
                                  color: Colors.black,
                                ),
                              ),
                              // const SizedBox(width: 5),
                              // Text(
                              //   ' X $quantity',
                              //   style: GoogleFonts.jost(
                              //     fontSize: 14.0,
                              //     color: Colors.grey.shade500,
                              //   ),
                              // ).visible(quantity != 0),
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
                  ),
                ],
              ),
            ),
            Text(
              '$currency${widget.productPrice}',
              style: GoogleFonts.jost(
                fontSize: 20.0,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    });
  }
}

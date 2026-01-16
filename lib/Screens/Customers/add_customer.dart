import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';
import '../../model/country_model.dart';
import '../../service/check_user_role_permission_provider.dart';
import 'Provider/customer_provider.dart';
import 'Repo/parties_repo.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';

class AddParty extends StatefulWidget {
  const AddParty({super.key, this.customerModel});
  final Party? customerModel;
  @override
  // ignore: library_private_types_in_public_api
  _AddPartyState createState() => _AddPartyState();
}

class _AddPartyState extends State<AddParty> {
  String groupValue = 'Retailer';
  String advanced = 'advance';
  String due = 'due';
  String openingBalanceType = 'due';
  bool expanded = false;
  final ImagePicker _picker = ImagePicker();
  bool showProgress = false;
  XFile? pickedImage;

  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  final creditLimitController = TextEditingController();
  final billingAddressController = TextEditingController();
  final billingCityController = TextEditingController();
  final billingStateController = TextEditingController();
  final shippingAddressController = TextEditingController();
  final shippingCityController = TextEditingController();
  final shippingStateController = TextEditingController();
  final billingZipCodeCountryController = TextEditingController();
  final shippingZipCodeCountryController = TextEditingController();
  final openingBalanceController = TextEditingController();

  final GlobalKey<FormState> _formKay = GlobalKey();
  FocusNode focusNode = FocusNode();

  List<Country> _countries = [];
  Country? _selectedBillingCountry;
  Country? _selectedShippingCountry;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  void _initializeFields() {
    final party = widget.customerModel;
    if (party != null) {
      nameController.text = party.name ?? '';
      emailController.text = party.email ?? '';
      addressController.text = party.address ?? '';
      // dueController.text = party.due?.toString() ?? '';
      creditLimitController.text = party.creditLimit?.toString() ?? '';
      openingBalanceController.text = party.openingBalance?.toString() ?? '';
      openingBalanceType = party.openingBalanceType ?? 'due';
      groupValue = party.type ?? 'Retailer';
      phoneController.text = party.phone ?? '';

      // Initialize billing address fields
      billingAddressController.text = party.billingAddress?.address ?? '';
      billingCityController.text = party.billingAddress?.city ?? '';
      billingStateController.text = party.billingAddress?.state ?? '';
      billingZipCodeCountryController.text = party.billingAddress?.zipCode ?? '';
      if (party.billingAddress?.country != null) {
        _selectedBillingCountry = _countries.firstWhere(
          (c) => c.name == party.billingAddress!.country,
        );
      }
      shippingAddressController.text = party.shippingAddress?.address ?? '';
      shippingCityController.text = party.shippingAddress?.city ?? '';
      shippingStateController.text = party.shippingAddress?.state ?? '';
      shippingZipCodeCountryController.text = party.shippingAddress?.zipCode ?? '';
      if (party.shippingAddress?.country != null) {
        _selectedShippingCountry = _countries.firstWhere(
          (c) => c.name == party.shippingAddress!.country,
        );
      }
    }
  }

  Future<void> _loadCountries() async {
    try {
      final String response = await rootBundle.loadString('assets/countrylist.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _countries = data.map((json) => Country.fromJson(json)).toList();
      });

      // Now that countries are loaded, initialize fields
      _initializeFields();
    } catch (e) {
      print('Error loading countries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(partiesProvider);
      final businessInfo = ref.watch(businessInfoProvider);
      final permissionService = PermissionService(ref);
      bool isReadOnly = (widget.customerModel?.branchId != businessInfo.value?.data?.user?.activeBranchId) &&
          widget.customerModel != null;
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            surfaceTintColor: kWhite,
            backgroundColor: Colors.white,
            title: Text(
              lang.S.of(context).addParty,
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0.0,
            bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: 1,
                )),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKay,
              child: Column(
                children: [
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang.S.of(context).pleaseEnterAValidPhoneNumber;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).phone,
                      hintText: lang.S.of(context).enterYourPhoneNumber,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  ///_________Name_______________________
                  TextFormField(
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        // return 'Please enter a valid Name';
                        return lang.S.of(context).pleaseEnterAValidName;
                      }
                      // You can add more validation logic as needed
                      return null;
                    },
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: lang.S.of(context).name,
                      hintText: lang.S.of(context).enterYourName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  ///_________opening balance_______________________
                  ///
                  TextFormField(
                    controller: openingBalanceController,
                    // 2. Use the variable here
                    readOnly: isReadOnly,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: lang.S.of(context).balance,
                      hintText: lang.S.of(context).enterOpeningBalance,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                              color: Color(0xffF7F7F7),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              )),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                // Optional: Change icon color if disabled
                                color: isReadOnly ? Colors.grey : kPeraColor,
                              ),
                              // items: ['Advance', 'Due'].map((entry) {
                              //   final valueToStore = entry.toLowerCase();
                              //   return DropdownMenuItem<String>(
                              //     value: valueToStore,
                              //     child: Text(
                              //       entry,
                              //       style: theme.textTheme.bodyLarge?.copyWith(color: kTitleColor),
                              //     ),
                              //   );
                              // }).toList(),
                              items: [
                                DropdownMenuItem<String>(
                                  value: advanced,
                                  child: Text(
                                    lang.S.of(context).advance,
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: due,
                                  child: Text(
                                    lang.S.of(context).due,
                                  ),
                                ),
                              ],
                              value: openingBalanceType,
                              // 3. LOGIC APPLIED HERE:
                              // If isReadOnly is true, set onChanged to null (disables it).
                              // If false, allow the function to run.
                              onChanged: isReadOnly
                                  ? null
                                  : (String? value) {
                                      setState(() {
                                        openingBalanceType = value!;
                                      });
                                    },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // TextFormField(
                  //   controller: openingBalanceController,
                  //   keyboardType: TextInputType.name,
                  //   decoration: InputDecoration(
                  //     labelText: lang.S.of(context).balance,
                  //     hintText: lang.S.of(context).enterOpeningBalance,
                  //     suffixIcon: Padding(
                  //       padding: const EdgeInsets.all(1.0),
                  //       child: Container(
                  //         padding: EdgeInsets.symmetric(horizontal: 10),
                  //         decoration: BoxDecoration(
                  //             color: Color(0xffF7F7F7),
                  //             borderRadius: BorderRadius.only(
                  //               topRight: Radius.circular(4),
                  //               bottomRight: Radius.circular(4),
                  //             )),
                  //         child: DropdownButtonHideUnderline(
                  //           child: DropdownButton<String>(
                  //             icon: Icon(
                  //               Icons.keyboard_arrow_down,
                  //               color: kPeraColor,
                  //             ),
                  //             items: ['Advance', 'Due'].map((entry) {
                  //               final valueToStore = entry.toLowerCase(); // 'advanced', 'due'
                  //               return DropdownMenuItem<String>(
                  //                 value: valueToStore,
                  //                 child: Text(
                  //                   entry, // show capitalized
                  //                   style: theme.textTheme.bodyLarge?.copyWith(color: kTitleColor),
                  //                 ),
                  //               );
                  //             }).toList(),
                  //             value: openingBalanceType,
                  //             onChanged: (String? value) {
                  //               setState(() {
                  //                 openingBalanceType = value!;
                  //               });
                  //             },
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  SizedBox(height: 20),

                  ///_______Type___________________________
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          fillColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return kMainColor;
                              }
                              return kPeraColor;
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                          groupValue: groupValue,
                          title: Text(
                            lang.S.of(context).customer,
                            maxLines: 1,
                            style: theme.textTheme.bodyMedium,
                          ),
                          value: 'Retailer',
                          onChanged: (value) {
                            setState(() {
                              groupValue = value.toString();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          fillColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return kMainColor;
                              }
                              return kPeraColor;
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                          groupValue: groupValue,
                          title: Text(
                            lang.S.of(context).dealer,
                            maxLines: 1,
                            style: theme.textTheme.bodyMedium,
                          ),
                          value: 'Dealer',
                          onChanged: (value) {
                            setState(() {
                              groupValue = value.toString();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          fillColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return kMainColor;
                              }
                              return kPeraColor;
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                          activeColor: kMainColor,
                          groupValue: groupValue,
                          title: Text(
                            lang.S.of(context).wholesaler,
                            maxLines: 1,
                            style: theme.textTheme.bodyMedium,
                          ),
                          value: 'Wholesaler',
                          onChanged: (value) {
                            setState(() {
                              groupValue = value.toString();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: kMainColor,
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          fillColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return kMainColor;
                              }
                              return kPeraColor;
                            },
                          ),
                          groupValue: groupValue,
                          title: Text(
                            lang.S.of(context).supplier,
                            maxLines: 1,
                            style: theme.textTheme.bodyMedium,
                          ),
                          value: 'Supplier',
                          onChanged: (value) {
                            setState(() {
                              groupValue = value.toString();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: showProgress,
                    child: const CircularProgressIndicator(
                      color: kMainColor,
                      strokeWidth: 5.0,
                    ),
                  ),
                  ExpansionPanelList(
                    expandIconColor: Colors.transparent,
                    expandedHeaderPadding: EdgeInsets.zero,
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        expanded == false ? expanded = true : expanded = false;
                      });
                    },
                    animationDuration: const Duration(milliseconds: 500),
                    elevation: 0,
                    dividerColor: Colors.white,
                    children: [
                      ExpansionPanel(
                        backgroundColor: kWhite,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return TextButton.icon(
                            style: ButtonStyle(
                              alignment: Alignment.center,
                              backgroundColor: WidgetStateColor.transparent,
                              overlayColor: WidgetStateColor.transparent,
                              surfaceTintColor: WidgetStateColor.transparent,
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.only(left: 70),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                expanded == false ? expanded = true : expanded = false;
                              });
                            },
                            label: Text(
                              lang.S.of(context).moreInfo,
                              style: theme.textTheme.titleSmall?.copyWith(color: Colors.red),
                            ),
                            icon: Icon(Icons.keyboard_arrow_down_outlined),
                            iconAlignment: IconAlignment.end,
                          );
                        },
                        body: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: kWhite,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        // ignore: sized_box_for_whitespace
                                        child: Container(
                                          height: 200.0,
                                          width: MediaQuery.of(context).size.width - 80,
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                GestureDetector(
                                                  onTap: () async {
                                                    pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                                                    setState(() {});
                                                    Future.delayed(const Duration(milliseconds: 100), () {
                                                      Navigator.pop(context);
                                                    });
                                                  },
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(
                                                        Icons.photo_library_rounded,
                                                        size: 60.0,
                                                        color: kMainColor,
                                                      ),
                                                      Text(
                                                        lang.S.of(context).gallery,
                                                        //'Gallery',
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          color: kMainColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 40.0,
                                                ),
                                                GestureDetector(
                                                  onTap: () async {
                                                    pickedImage = await _picker.pickImage(source: ImageSource.camera);
                                                    setState(() {});
                                                    Future.delayed(const Duration(milliseconds: 100), () {
                                                      Navigator.pop(context);
                                                    });
                                                  },
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(
                                                        Icons.camera,
                                                        size: 60.0,
                                                        color: kGreyTextColor,
                                                      ),
                                                      Text(
                                                        lang.S.of(context).camera,
                                                        //'Camera',
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          color: kGreyTextColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: pickedImage == null
                                          ? const DecorationImage(
                                              image: AssetImage('images/no_shop_image.png'),
                                              fit: BoxFit.cover,
                                            )
                                          : DecorationImage(
                                              image: FileImage(File(pickedImage!.path)),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 35,
                                      width: 35,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white, width: 2),
                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                        color: kMainColor,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            ///__________email__________________________
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  labelText: lang.S.of(context).email,
                                  //hintText: 'Enter your email address',
                                  hintText: lang.S.of(context).hintEmail),
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: addressController,
                              decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  labelText: lang.S.of(context).address,
                                  //hintText: 'Enter your address'
                                  hintText: lang.S.of(context).hintEmail),
                            ),
                            // SizedBox(height: 20),
                            // TextFormField(
                            //   controller: dueController,
                            //   inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                            //   keyboardType: TextInputType.number,
                            //   decoration: InputDecoration(
                            //     border: const OutlineInputBorder(),
                            //     floatingLabelBehavior: FloatingLabelBehavior.always,
                            //     labelText: lang.S.of(context).previousDue,
                            //     hintText: lang.S.of(context).amount,
                            //   ),
                            // ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: creditLimitController,
                              decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  labelText: lang.S.of(context).creditLimit,
                                  hintText: 'Ex: 800'),
                            ),
                            SizedBox(height: 4),
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: kGreyTextColor,
                                visualDensity: VisualDensity(vertical: -2, horizontal: -4),
                                tilePadding: EdgeInsets.zero,
                                trailing: SizedBox.shrink(),
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FeatherIcons.plus,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      lang.S.of(context).billingAddress,
                                      style: theme.textTheme.titleMedium,
                                    )
                                  ],
                                ),
                                children: [
                                  SizedBox(height: 10),
                                  //___________Billing Address________________
                                  TextFormField(
                                    controller: billingAddressController,
                                    decoration: InputDecoration(
                                      labelText: lang.S.of(context).address,
                                      hintText: lang.S.of(context).enterAddress,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  //--------------billing city------------------------
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: billingCityController,
                                          decoration: InputDecoration(
                                            labelText: lang.S.of(context).city,
                                            hintText: lang.S.of(context).cityName,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: billingStateController,
                                          decoration: InputDecoration(
                                            labelText: lang.S.of(context).state,
                                            hintText: lang.S.of(context).stateName,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  //--------------billing state------------------------

                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      //--------------billing zip code------------------------
                                      Expanded(
                                        child: TextFormField(
                                          controller: billingZipCodeCountryController,
                                          decoration: InputDecoration(
                                            labelText: lang.S.of(context).zip,
                                            hintText: lang.S.of(context).zipCode,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      //--------------billing country------------------------
                                      Flexible(
                                        child: DropdownButtonFormField<Country>(
                                          initialValue: _selectedBillingCountry,
                                          hint: Text(lang.S.of(context).chooseCountry),
                                          onChanged: (Country? newValue) {
                                            setState(() {
                                              _selectedBillingCountry = newValue;
                                            });
                                            if (newValue != null) {
                                              print('Selected: ${newValue.name} (${newValue.code})');
                                            }
                                          },
                                          items: _countries.map<DropdownMenuItem<Country>>((Country country) {
                                            return DropdownMenuItem<Country>(
                                              value: country,
                                              child: Row(
                                                children: [
                                                  Text(country.emoji),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      country.name,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          decoration: kInputDecoration.copyWith(
                                            labelText: lang.S.of(context).country,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: kGreyTextColor,
                                tilePadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(horizontal: -4, vertical: -2),
                                trailing: SizedBox.shrink(),
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(FeatherIcons.plus, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      lang.S.of(context).shippingAddress,
                                      style: theme.textTheme.titleMedium,
                                    )
                                  ],
                                ),
                                children: [
                                  SizedBox(height: 10),
                                  //___________Billing Address________________
                                  TextFormField(
                                    controller: shippingAddressController,
                                    decoration: InputDecoration(
                                      labelText: lang.S.of(context).address,
                                      hintText: lang.S.of(context).enterAddress,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  //--------------billing city------------------------
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: shippingCityController,
                                          decoration: InputDecoration(
                                            labelText: lang.S.of(context).city,
                                            hintText: lang.S.of(context).cityName,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: shippingStateController,
                                          decoration: InputDecoration(
                                            labelText: lang.S.of(context).state,
                                            hintText: lang.S.of(context).stateName,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  //--------------billing state------------------------

                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      //--------------billing zip code------------------------
                                      Expanded(
                                        child: TextFormField(
                                          controller: shippingZipCodeCountryController,
                                          decoration: InputDecoration(
                                            labelText: lang.S.of(context).zip,
                                            hintText: lang.S.of(context).zipCode,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      //--------------billing country------------------------
                                      Flexible(
                                        child: DropdownButtonFormField<Country>(
                                          initialValue: _selectedShippingCountry,
                                          hint: Text(lang.S.of(context).chooseCountry),
                                          onChanged: (Country? newValue) {
                                            setState(() {
                                              _selectedShippingCountry = newValue;
                                            });
                                            if (newValue != null) {
                                              print('Selected: ${newValue.name} (${newValue.code})');
                                            }
                                          },
                                          items: _countries.map<DropdownMenuItem<Country>>((Country country) {
                                            return DropdownMenuItem<Country>(
                                              value: country,
                                              child: Row(
                                                children: [
                                                  Text(country.emoji),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      country.name,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          decoration: kInputDecoration.copyWith(
                                            labelText: lang.S.of(context).country,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        isExpanded: expanded,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!permissionService.hasPermission(Permit.partiesCreate.value)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(lang.S.of(context).partyCreateWarn),
                          ),
                        );
                        return;
                      }

                      num parseOrZero(String? input) {
                        if (input == null || input.isEmpty) return 0;
                        return num.tryParse(input) ?? 0;
                      }

                      Customer customer = Customer(
                        id: widget.customerModel?.id.toString() ?? '',
                        name: nameController.text,
                        phone: phoneController.text ?? '',
                        customerType: groupValue,
                        image: pickedImage != null ? File(pickedImage!.path) : null,
                        email: emailController.text,
                        address: addressController.text,
                        openingBalanceType: openingBalanceType.toString(),
                        openingBalance: parseOrZero(openingBalanceController.text),
                        creditLimit: parseOrZero(creditLimitController.text),
                        billingAddress: billingAddressController.text,
                        billingCity: billingCityController.text,
                        billingState: billingStateController.text,
                        billingZipcode: billingZipCodeCountryController.text,
                        billingCountry: _selectedBillingCountry?.name.toString() ?? '',
                        shippingAddress: shippingAddressController.text,
                        shippingCity: shippingCityController.text,
                        shippingState: shippingStateController.text,
                        shippingZipcode: shippingZipCodeCountryController.text,
                        shippingCountry: _selectedShippingCountry?.name.toString() ?? '',
                      );

                      final partyRepo = PartyRepository();
                      if (widget.customerModel == null) {
                        // Add new
                        await partyRepo.addParty(
                          ref: ref,
                          context: context,
                          customer: customer,
                        );
                      } else {
                        await partyRepo.updateParty(
                          ref: ref,
                          context: context,
                          customer: customer,
                        );
                      }
                    },
                    child: Text(lang.S.of(context).save),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class Customer {
  String? id;
  String name;
  String? phone;
  String? customerType;
  File? image;
  String? email;
  String? address;
  String? openingBalanceType;
  num? openingBalance;
  num? creditLimit;
  String? billingAddress;
  String? billingCity;
  String? billingState;
  String? billingZipcode;
  String? billingCountry;
  String? shippingAddress;
  String? shippingCity;
  String? shippingState;
  String? shippingZipcode;
  String? shippingCountry;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.customerType,
    this.image,
    this.email,
    this.address,
    this.openingBalanceType,
    this.openingBalance,
    this.creditLimit,
    this.billingAddress,
    this.billingCity,
    this.billingState,
    this.billingZipcode,
    this.billingCountry,
    this.shippingAddress,
    this.shippingCity,
    this.shippingState,
    this.shippingZipcode,
    this.shippingCountry,
  });
}

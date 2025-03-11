import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';
import 'package:mobile_pos/Screens/Profile%20Screen/profile_details.dart';
import 'package:mobile_pos/Screens/User%20Roles/user_role_screen.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../model/business_info_model.dart';
import '../Authentication/Repo/logout_repo.dart';
import '../Currency/currency_screen.dart';
import '../Shimmers/home_screen_appbar_shimmer.dart';
import '../barcode/gererate_barcode.dart';
import '../language/language.dart';
import '../subscription/package_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen> {
  bool expanded = false;
  bool expandedHelp = false;
  bool expandedAbout = false;
  bool selected = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    printerIsEnable();
  }

  void printerIsEnable() async {
    final prefs = await SharedPreferences.getInstance();

    isPrintEnable = prefs.getBool('isPrintEnable') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer(builder: (context, ref, _) {
        AsyncValue<BusinessInformation> businessInfo = ref.watch(businessInfoProvider);
        return GlobalPopup(
          child: Scaffold(
            backgroundColor: kWhite,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 0.0,
                    color: kWhite,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: businessInfo.when(data: (details) {
                        return Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                const ProfileDetails().launch(context);
                              },
                              child: Container(
                                height: 42,
                                width: 42,
                                decoration: BoxDecoration(
                                  image: details.pictureUrl == null
                                      ? const DecorationImage(image: AssetImage('images/no_shop_image.png'), fit: BoxFit.cover)
                                      : DecorationImage(image: NetworkImage(APIConfig.domain + details.pictureUrl.toString()), fit: BoxFit.cover),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    details.user?.role == 'staff' ? '${details.companyName ?? ''} [${details.user?.name ?? ''}]' : details.companyName ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    details.category?.name ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.normal,
                                      color: kGreyTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }, error: (e, stack) {
                        return Text(e.toString());
                      }, loading: () {
                        return const HomeScreenAppBarShimmer();
                      }),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      lang.S.of(context).profile,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    onTap: () {
                      const ProfileDetails().launch(context);
                    },
                    leading: SvgPicture.asset(
                      'assets/profile.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: kGreyTextColor,
                      size: 20,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      lang.S.of(context).printing,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    leading: SvgPicture.asset(
                      'assets/print.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: Transform.scale(
                      scale: 0.7,
                      child: SizedBox(
                        height: 22,
                        width: 40,
                        child: Switch.adaptive(
                          // activeColor: kMainColor,
                          // inactiveTrackColor: kGreyTextColor,
                          activeTrackColor: kMainColor,
                          // thumbColor: const WidgetStatePropertyAll(Colors.white),
                          value: isPrintEnable,
                          onChanged: (bool value) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isPrintEnable', value);
                            setState(() {
                              isPrintEnable = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),

                  ///_________subscription_____________________________________________________
                  ListTile(
                    title: Text(
                      lang.S.of(context).subscription,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    onTap: () {
                      const PackageScreen().launch(context);
                    },
                    leading: SvgPicture.asset(
                      'assets/subscription.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: kGreyTextColor,
                      size: 18,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),

                  ///_________DashBoard_____________________________________________________
                  ListTile(
                    title: Text(
                      lang.S.of(context).dashboard,
                      // 'Dashboard',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    onTap: () {
                      const DashboardScreen().launch(context);
                    },
                    leading: SvgPicture.asset(
                      'assets/dashboard.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: kGreyTextColor,
                      size: 18,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),

                  ///___________user_role___________________________________________________________
                  ListTile(
                    title: Text(
                      lang.S.of(context).userRole,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    onTap: () {
                      const UserRoleScreen().launch(context);
                    },
                    leading: SvgPicture.asset(
                      'assets/userRole.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: kGreyTextColor,
                      size: 18,
                    ),
                  ).visible(businessInfo.value?.user?.role != 'staff'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),

                  ///____________Currency________________________________________________
                  ListTile(
                    onTap: () async {
                      await const CurrencyScreen().launch(context);
                      setState(() {});
                    },
                    title: Text(
                      lang.S.of(context).currency,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    leading: SvgPicture.asset(
                      'assets/currency.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '($currency)',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(
                          width: 4.0,
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: kGreyTextColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),

                  ///____________barcode_generator________________________________________________
                  ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BarcodeGeneratorScreen(),
                      ),
                    ),
                    title: Text(
                      lang.S.of(context).barcodeGenerator,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    leading: SvgPicture.asset(
                      'assets/print.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: kGreyTextColor,
                      size: 18,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),

                  ///____________________language_________________________________________________________
                  ListTile(
                    title: Text(
                      lang.S.of(context).selectLang,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final data = prefs.getString('lang');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectLanguage(alreadySelectedLanguage: data),
                        ),
                      );
                    },
                    leading: SvgPicture.asset(
                      'assets/language.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: kGreyTextColor,
                      size: 18,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),

                  ///__________log_Out_______________________________________________________________
                  ListTile(
                    title: Text(
                      lang.S.of(context).logOut,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    onTap: () async {
                      ref.invalidate(businessInfoProvider);
                      EasyLoading.show(
                        status: lang.S.of(context).logOut,
                        //'Log out'
                      );
                      LogOutRepo repo = LogOutRepo();
                      await repo.signOutApi(context: context, ref: ref);
                    },
                    leading: SvgPicture.asset(
                      'assets/logout.svg',
                      height: 36,
                      width: 36,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: kGreyTextColor,
                      size: 18,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1.0,
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'NPOS V-$appVersion',
                          style: GoogleFonts.poppins(
                            color: kGreyTextColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

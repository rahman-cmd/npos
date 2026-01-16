import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/Sales/provider/sales_cart_provider.dart';
import 'package:mobile_pos/Screens/Customers/Provider/customer_provider.dart';
import 'package:mobile_pos/Screens/Customers/add_customer.dart';
import 'package:mobile_pos/Screens/Customers/customer_details.dart';
import 'package:mobile_pos/Screens/Sales/add_sales.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/widgets/empty_widget/_empty_widget.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';
import '../../currency.dart';
import '../../service/check_actions_when_no_branch.dart';
import '../../service/check_user_role_permission_provider.dart';
import 'Repo/parties_repo.dart';

// 1. Combine the screens into a single class with a parameter for mode
class PartyListScreen extends StatefulWidget {
  // Use a boolean to determine the screen's purpose
  final bool isSelectionMode;

  const PartyListScreen({super.key, this.isSelectionMode = false});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  late Color color;
  bool _isRefreshing = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    ref.refresh(partiesProvider);

    await Future.delayed(const Duration(seconds: 1));
    _isRefreshing = false;
  }

  String? partyType;

  // Define party types based on the mode
  List<String> get availablePartyTypes {
    if (widget.isSelectionMode) {
      // For Sales/Selection mode, exclude 'Supplier'
      return [
        PartyType.customer,
        PartyType.dealer,
        PartyType.wholesaler,
      ];
    } else {
      // For General List/Management mode, include all
      return [
        PartyType.customer,
        PartyType.supplier,
        PartyType.dealer,
        PartyType.wholesaler,
      ];
    }
  }

  Future<void> showDeleteConfirmationAlert({
    required BuildContext context,
    required String id,
    required WidgetRef ref,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context1) {
        return AlertDialog(
          title: Text(
            lang.S.of(context).confirmPassword,
            //'Confirm Delete'
          ),
          content: Text(
            lang.S.of(context).areYouSureYouWant,
            //'Are you sure you want to delete this party?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lang.S.of(context).cancel,
                //'Cancel'
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final party = PartyRepository();
                await party.deleteParty(id: id, context: context, ref: ref);
              },
              child: Text(lang.S.of(context).delete,
                  // 'Delete',
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, __) {
        final providerData = ref.watch(partiesProvider);
        final businessInfo = ref.watch(businessInfoProvider);
        final permissionService = PermissionService(ref);

        // Determine App Bar Title based on mode
        final appBarTitle = widget.isSelectionMode
            ? lang.S.of(context).chooseCustomer // Sales title
            : lang.S.of(context).partyList; // Management title

        return businessInfo.when(data: (details) {
          return GlobalPopup(
            child: Scaffold(
              backgroundColor: kWhite,
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                backgroundColor: Colors.white,
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.black),
                elevation: 0.0,
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  appBarTitle,
                  style: _theme.textTheme.titleMedium?.copyWith(color: Colors.black),
                ),
              ),
              body: RefreshIndicator.adaptive(
                onRefresh: () => refreshData(ref),
                child: providerData.when(data: (partyList) {
                  // Permission check only required for the management view
                  if (!widget.isSelectionMode && !permissionService.hasPermission(Permit.partiesRead.value)) {
                    return const Center(child: PermitDenyWidget());
                  }
                  final filteredParties = partyList.where((c) {
                    final normalizedType = (c.type ?? '').toLowerCase();

                    // Filter out suppliers ONLY if in selection mode
                    if (widget.isSelectionMode && normalizedType == 'supplier') {
                      return false;
                    }

                    final nameMatches = !_isSearching || _searchController.text.isEmpty
                        ? true
                        : (c.name ?? '').toLowerCase().contains(_searchController.text.toLowerCase());

                    final effectiveType = normalizedType == 'retailer' ? 'customer' : normalizedType;

                    final typeMatches = partyType == null || partyType!.isEmpty ? true : effectiveType == partyType;

                    return nameMatches && typeMatches;
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: TextFormField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: lang.S.of(context).search,
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                        color: const Color(0xffF7F7F7),
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        )),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        hint: Text(lang.S.of(context).selectType),
                                        icon: partyType != null
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear,
                                                  color: kMainColor,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    partyType = null;
                                                  });
                                                },
                                              )
                                            : const Icon(Icons.keyboard_arrow_down, color: kPeraColor),
                                        value: partyType,
                                        onChanged: (String? value) {
                                          setState(() {
                                            partyType = value;
                                          });
                                        },
                                        // Use the list defined by the mode
                                        items: availablePartyTypes.map((entry) {
                                          final valueToStore = entry.toLowerCase();
                                          return DropdownMenuItem<String>(
                                            value: valueToStore,
                                            child: Text(
                                              getPartyTypeLabel(context, valueToStore),
                                              style: _theme.textTheme.bodyLarge?.copyWith(color: kTitleColor),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          onChanged: (value) {
                            setState(() {
                              _isSearching = value.isNotEmpty;
                            });
                          },
                        ),
                      ),

                      // 3. Show Walk-In Customer ONLY in selection mode
                      if (widget.isSelectionMode)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          onTap: () {
                            AddSalesScreen(customerModel: null).launch(context);
                            ref.refresh(cartNotifier);
                          },
                          leading: SizedBox(
                            height: 40.0,
                            width: 40.0,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.asset(
                                  'images/no_shop_image.png',
                                  fit: BoxFit.cover,
                                  width: 120.0,
                                  height: 120.0,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            lang.S.of(context).walkInCustomer,
                            style: _theme.textTheme.bodyMedium?.copyWith(
                              color: kTitleColor,
                              fontSize: 16.0,
                            ),
                          ),
                          subtitle: Text(
                            lang.S.of(context).guest,
                            style: _theme.textTheme.bodyLarge,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: Color(0xff4B5563),
                          ),
                        ),
                      filteredParties.isNotEmpty
                          ? Expanded(
                              child: ListView.builder(
                                itemCount: filteredParties.length,
                                shrinkWrap: true,
                                physics:
                                    const AlwaysScrollableScrollPhysics(), // Use AlwaysScrollableScrollPhysics for the main list
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (_, index) {
                                  final item = filteredParties[index];
                                  final normalizedType = (item.type ?? '').toLowerCase();

                                  // Color logic (unchanged)
                                  color = Colors.white;
                                  if (normalizedType == 'retailer' || normalizedType == 'customer') {
                                    color = const Color(0xFF56da87);
                                  }
                                  if (normalizedType == 'wholesaler') color = const Color(0xFF25a9e0);
                                  if (normalizedType == 'dealer') color = const Color(0xFFff5f00);
                                  if (normalizedType == 'supplier') color = const Color(0xFFA569BD);

                                  // final effectiveDisplayType = normalizedType == 'retailer'
                                  //     ? 'Customer'
                                  //     : normalizedType == 'wholesaler'
                                  //         ? lang.S.of(context).wholesaler
                                  //         : normalizedType == 'dealer'
                                  //             ? lang.S.of(context).dealer
                                  //             : normalizedType == 'supplier'
                                  //                 ? lang.S.of(context).supplier
                                  //                 : item.type ?? '';

                                  String effectiveDisplayType;

                                  if (normalizedType == 'retailer') {
                                    effectiveDisplayType = lang.S.of(context).customer;
                                  } else if (normalizedType == 'wholesaler') {
                                    effectiveDisplayType = lang.S.of(context).wholesaler;
                                  } else if (normalizedType == 'dealer') {
                                    effectiveDisplayType = lang.S.of(context).dealer;
                                  } else if (normalizedType == 'supplier') {
                                    effectiveDisplayType = lang.S.of(context).supplier;
                                  } else {
                                    effectiveDisplayType = item.type ?? '';
                                  }

                                  // Due/Advance/No Due Logic (from previous step)
                                  String statusText;
                                  Color statusColor;
                                  num? statusAmount;

                                  if (item.due != null && item.due! > 0) {
                                    statusText = lang.S.of(context).due;
                                    statusColor = const Color(0xFFff5f00);
                                    statusAmount = item.due;
                                  } else if (item.openingBalanceType?.toLowerCase() == 'advance' &&
                                      item.wallet != null &&
                                      item.wallet! > 0) {
                                    statusText = lang.S.of(context).advance;
                                    statusColor = DAppColors.kSecondary;
                                    statusAmount = item.wallet;
                                  } else {
                                    statusText = lang.S.of(context).noDue;
                                    statusColor = DAppColors.kSecondary;
                                    statusAmount = null;
                                  }

                                  return ListTile(
                                    visualDensity: const VisualDensity(vertical: -2),
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () {
                                      // 4. OnTap action based on mode
                                      if (widget.isSelectionMode) {
                                        // Selection Mode: Go to AddSalesScreen
                                        AddSalesScreen(customerModel: item).launch(context);
                                        ref.refresh(cartNotifier);
                                      } else {
                                        // Management Mode: Go to CustomerDetails
                                        CustomerDetails(party: item).launch(context);
                                      }
                                    },
                                    leading: item.image != null
                                        ? Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: DAppColors.kBorder, width: 0.3),
                                              image: DecorationImage(
                                                image: NetworkImage('${APIConfig.domain}${item.image ?? ''}'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        : CircleAvatarWidget(name: item.name),
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _theme.textTheme.bodyMedium?.copyWith(
                                              color: kTitleColor,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusAmount != null ? '$currency${statusAmount.toStringAsFixed(2)}' : '',
                                          style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 16.0),
                                        ),
                                      ],
                                    ),
                                    subtitle: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            effectiveDisplayType,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _theme.textTheme.bodyMedium?.copyWith(
                                              color: color,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: _theme.textTheme.bodyMedium?.copyWith(
                                            color: statusColor,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      offset: const Offset(0, 30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (BuildContext bc) => [
                                        PopupMenuItem(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CustomerDetails(party: item),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.remove_red_eye,
                                                color: kGreyTextColor,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8.0),
                                              Text(
                                                lang.S.of(context).view,
                                                style: TextStyle(color: kGreyTextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          onTap: () async {
                                            bool result = await checkActionWhenNoBranch(ref: ref, context: context);
                                            if (!permissionService.hasPermission(Permit.partiesUpdate.value)) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: Colors.red,
                                                  content: Text(lang.S.of(context).updatePartyWarn),
                                                ),
                                              );
                                              return;
                                            }
                                            if (result) {
                                              AddParty(customerModel: item).launch(context);
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                IconlyBold.edit,
                                                color: kGreyTextColor,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8.0),
                                              Text(
                                                lang.S.of(context).edit,
                                                style: TextStyle(color: kGreyTextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          onTap: () async {
                                            bool result = await checkActionWhenNoBranch(ref: ref, context: context);
                                            if (!permissionService.hasPermission(Permit.partiesDelete.value)) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: Colors.red,
                                                  content: Text(lang.S.of(context).deletePartyWarn),
                                                ),
                                              );
                                              return;
                                            }
                                            if (result) {
                                              await showDeleteConfirmationAlert(
                                                  context: context, id: item.id.toString(), ref: ref);
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                IconlyBold.delete,
                                                color: kGreyTextColor,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8.0),
                                              Text(
                                                lang.S.of(context).delete,
                                                style: TextStyle(color: kGreyTextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        Navigator.pushNamed(context, '$value');
                                      },
                                      child: const Icon(
                                        FeatherIcons.moreVertical,
                                        color: kGreyTextColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: EmptyWidget(
                                message: TextSpan(text: lang.S.of(context).noParty),
                              ),
                            ),
                    ],
                  );
                }, error: (e, stack) {
                  return Text(e.toString());
                }, loading: () {
                  return const Center(child: CircularProgressIndicator());
                }),
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ElevatedButton.icon(
                  style: OutlinedButton.styleFrom(
                    maximumSize: const Size(double.infinity, 48),
                    minimumSize: const Size(double.infinity, 48),
                    disabledBackgroundColor: _theme.colorScheme.primary.withAlpha(15),
                    disabledForegroundColor: const Color(0xff567DF4).withOpacity(0.05),
                  ),
                  onPressed: () async {
                    bool result = await checkActionWhenNoBranch(ref: ref, context: context);
                    // Check logic based on business info (kept original logic)
                    if (result) {
                      if (details.data?.subscriptionDate != null && details.data?.enrolledPlan != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddParty()));
                      } else if (!widget.isSelectionMode) {
                        // Allow navigation if not in selection mode and subscription check fails (or fix subscription check)
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddParty()));
                      }
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  iconAlignment: IconAlignment.start,
                  label: Text(
                    lang.S.of(context).addCustomer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _theme.textTheme.bodyMedium?.copyWith(
                      color: _theme.colorScheme.primaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }, error: (e, stack) {
          return Text(e.toString());
        }, loading: () {
          return const Center(child: CircularProgressIndicator());
        });
      },
    );
  }
}

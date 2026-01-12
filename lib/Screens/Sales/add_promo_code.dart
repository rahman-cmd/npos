import 'package:flutter/material.dart';
import 'package:mobile_pos/GlobalComponents/button_global.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';

class AddPromoCode extends StatefulWidget {
  const AddPromoCode({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AddPromoCodeState createState() => _AddPromoCodeState();
}

class _AddPromoCodeState extends State<AddPromoCode> {
  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            lang.S.of(context).promoCode,
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0.0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppTextField(
                  textFieldType: TextFieldType.NAME,
                  decoration: const InputDecoration(border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always, labelText: 'Add Promo Code'),
                ),
              ),
              ElevatedButton(
                onPressed: null,
                child: Text(lang.S.of(context).submit),
              ),
              Center(
                child: Text(
                  lang.S.of(context).seeAllPromoCode,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

class ReturnedTagWidget extends StatelessWidget {
  const ReturnedTagWidget({Key? key, required this.show}) : super(key: key);

  final bool show;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: show,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: const BorderRadius.all(Radius.circular(10))),
          child: Text(
            lang.S.of(context).returned,
            style: TextStyle(color: Colors.orange),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

Widget buildInvoiceLogo({required ImageProvider image}) {
  return Container(
    height: 70,
    width: 70,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      image: DecorationImage(fit: BoxFit.cover, image: image),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../constant.dart';

Future<bool?> invoiceDeleteAlert({required BuildContext context, required String type}) async {
  return await showDialog<bool>(
      context: context,
      builder: (context2) => AlertDialog(
            title:  Text('Are you sure to delete this $type?'),
            content:  Text(
              'The sale will be deleted and all the data will be deleted about this $type.Are you sure to delete this?',
              maxLines: 5,
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.of(context2).pop(false);
                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: const BorderRadius.all(Radius.circular(30)),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context2).pop(true);
                      },
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          color: kMainColor,
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        child: const Center(
                          child: Text(
                            'Delete',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ));
}

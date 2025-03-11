import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/GlobalComponents/button_global.dart';
import '../constant.dart';
import 'internet_connection_notifier.dart'; // Update with the correct path

class GlobalPopup extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalPopup({Key? key, required this.child}) : super(key: key);

  @override
  _GlobalPopupState createState() => _GlobalPopupState();
}

class _GlobalPopupState extends ConsumerState<GlobalPopup> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tryAgain() async {
    final notifier = ref.read(internetConnectionProvider);
    await notifier.checkConnection();
    if (notifier.isConnected) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!ref.watch(internetConnectionProvider).isConnected)
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: kMainColor, size: 100),
                    const SizedBox(height: 20),
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(color: kTitleColor, fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    UpdateButton(text: "Try Again", onpressed: _tryAgain),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
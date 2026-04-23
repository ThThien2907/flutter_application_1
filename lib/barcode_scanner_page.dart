import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          if (_isScanned) return;

          final barcodes = barcodeCapture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue;

            if (code != null) {
              _isScanned = true;

              // Trả kết quả về màn trước
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
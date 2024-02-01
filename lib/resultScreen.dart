import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class resultPage extends StatefulWidget {
  const resultPage({super.key});

  @override
  _resultPage createState() => _resultPage();
}

class _resultPage extends State<resultPage> {
  String qrCodeResult = "Not Yet Scanned";

  Future<void> scanQR() async {
    try {
      final codeScanner = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', false, ScanMode.QR);
      if (!mounted) return;
      setState(() {
        qrCodeResult = codeScanner.toString();
      });
    } on PlatformException {
      qrCodeResult = 'failed to scan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan QR Code"),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //Message displayed over here
            Text(
              "Result",
              style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              qrCodeResult,
              style: TextStyle(
                fontSize: 20.0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 20.0,
            ),

            //Button to scan QR code
            ElevatedButton(
              onPressed: () {
                scanQR();
              },
              child: Text(
                "Open Scanner",
                style: TextStyle(color: Colors.indigo[900]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:covid_app/resultScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info/device_info.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Location location = Location();
  String certificationData = '';
  bool isCovidPositive = false;
  bool isBluetoothEnabled = false;
  bool isLocationEnabled = false;
  bool isScanning = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _getCovidPositiveStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool('isCovidPositive') ?? false;

    setState(() {
      isCovidPositive = status;
    });
  }

  Future<void> _setCovidPositiveStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isCovidPositive', status);

    setState(() {
      isCovidPositive = status;
    });

    // Send COVID positive status to the backend
    await _sendCovidPositiveStatusToBackend(status);
  }

  Future<void> _checkLocationStatus() async {
    bool isEnabled = await location.serviceEnabled();
    setState(() {
      isLocationEnabled = isEnabled;
    });
  }

  Future<void> scanQR() async {
    try {
      final codeScanner = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', false, ScanMode.QR);
      if (!mounted) return;
      setState(() {
        certificationData = codeScanner.toString();
        _showResultDialog(context, 'Scan Result', certificationData);
      });
    } on PlatformException {
      _showResultDialog(context, 'Scan failed', 'Failed to scan QR code');
      certificationData = 'failed to scan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Covid Scanner'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  scanQR();
                },
                child: Text('Start QR Scan'),
              ),
              ElevatedButton(
                onPressed: () {
                  _sendQRData();
                },
                child: Text('Send QR Data'),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _setCovidPositiveStatus(true);
                      },
                      child: Text('Flag as COVID Positive'),
                      style: ElevatedButton.styleFrom(
                        primary: isCovidPositive ? Colors.red : null,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('Certification Data: $certificationData'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _storeCertificationData(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('certificationData', data);

    setState(() {
      certificationData = data;
    });
  }

  Future<void> _sendCovidPositiveStatusToBackend(bool status) async {
    // Replace with your backend API endpoint
    String apiUrl = 'http://192.168.11.103:8000/api/covidflags';
    Map<String, dynamic> requestBody = {"user_id": 1, "positive": status};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        print('COVID positive status sent successfully.');
        _showResultDialog(
            context, 'Flagged positive', 'Successfully flagged as POSITIVE!');
      } else {
        print(
            'Failed to send COVID positive status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending COVID positive status: $e');
    }
  }

  Future<void> _sendQRData() async {
    // Replace with your backend API endpoint
    String apiUrl = 'http://192.168.11.103:8000/api/qrcodes';
    List<String> dataFields = certificationData.split('\n');
    Map<String, dynamic> requestBody = {};
    for (String field in dataFields) {
      List<String> keyValue = field.split(':');
      if (keyValue.length == 2) {
        String key = keyValue[0].trim();
        String value = keyValue[1].trim();
        requestBody[key] = value;
      }
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        print('QR data sent successfully.');
        _showResultDialog(context, 'Success', 'QR data sent successfully.');
      } else {
        print('Failed to send QR data. Status code: ${response.toString()}');
      }
    } catch (e) {
      print('Error sending QR data: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showResultDialog(BuildContext context, String title, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

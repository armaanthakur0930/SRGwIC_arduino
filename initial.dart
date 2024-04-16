import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:srgwic/home_page.dart'; // Import the HomePage file

class InitialPage extends StatefulWidget {
  const InitialPage({Key? key}) : super(key: key);

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  int times = 0;

  void _getDevices() async {
    var res = await _bluetooth.getBondedDevices();
    setState(() => _devices = res);
  }

  void _receiveData() {
    _connection?.input?.listen(
          (event) {
        String receivedString = String.fromCharCodes(event);
        List<String> dataParts = receivedString.split(':');
        if (dataParts.length == 2) {
          String ingredientName = "Sugar"; // Hardcoded ingredient name
          double weight = double.tryParse(dataParts[1].trim()) ?? 0.0;

          // Check if the weight is more than 500 grams
          if (weight >= 500.0) {
            // Send the data to HomePage for API request
            Map<String, dynamic> ingredientData = {
              'ingredientName': ingredientName,
              'weight': weight,
            };
            _sendToHomePage(ingredientData);
          }
        }
      },
      onError: (dynamic error) {
        // Handle any errors in receiving data
        print('Error receiving data: $error');
      },
      onDone: () {
        // Handle when the connection is closed
        print('Connection closed');
      },
    );
  }

  void _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  @override
  void initState() {
    super.initState();

    _requestPermission();

    _bluetooth.state.then((state) {
      setState(() => _bluetoothState = state.isEnabled);
    });

    _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BluetoothState.STATE_OFF:
          setState(() => _bluetoothState = false);
          break;
        case BluetoothState.STATE_ON:
          setState(() => _bluetoothState = true);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Link to the Smart Canister',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _controlBT(),
            const SizedBox(height: 20),
            _infoDevice(),
            const SizedBox(height: 20),
            Expanded(child: _listDevices()),
            const SizedBox(height: 20),
            _addDeviceInstructions(),
            const SizedBox(height: 20),
            if (_connection?.isConnected ?? false) _continueButton(),
          ],
        ),
      ),
    );
  }

  Widget _controlBT() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      title: Text(
        _bluetoothState ? "Bluetooth is ON" : "Bluetooth is OFF",
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
          color: _bluetoothState ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _infoDevice() {
    return Card(
      color: Colors.grey.shade200,
      child: ListTile(
        title: Text(
          "Connected to: ${_deviceConnected?.name ?? "None"}",
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: _connection?.isConnected ?? false
            ? TextButton(
          onPressed: () async {
            await _connection?.finish();
            setState(() => _deviceConnected = null);
          },
          child: const Text(
            "Disconnect",
            style: TextStyle(color: Colors.red),
          ),
        )
            : TextButton(
          onPressed: _getDevices,
          child: const Text(
            "View Bluetooth Devices",
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _listDevices() {
    return _isConnecting
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Card(
          child: ListTile(
            title: Text(device.name ?? device.address),
            trailing: ElevatedButton(
              onPressed: () async {
                setState(() => _isConnecting = true);
                await _establishBluetoothConnection(device);
                setState(() => _isConnecting = false);
              },
              child: const Text('Connect'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _establishBluetoothConnection(BluetoothDevice device) async {
    try {
      print('Connecting to ${device.name}...');
      _connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');

      setState(() {
        _deviceConnected = device;
      });

      _receiveData();
    } catch (e) {
      print('Error connecting to device: $e');
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Widget _addDeviceInstructions() {
    return Container(
      padding: EdgeInsets.all(10),
      color: Colors.grey.shade300,
      child: Text(
        "To add a new device, open System Settings, and then select Bluetooth. Add a new connection.",
        style: TextStyle(
          fontFamily: 'Roboto',
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _continueButton() {
    return ElevatedButton(
      onPressed: () {
        // Navigate to Home Page or any desired page
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: Text(
        "Continue",
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _sendToHomePage(Map<String, dynamic> ingredientData) {
    // Navigate to HomePage with ingredient data
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(ingredientData: ingredientData)));
  }
}

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint("Error getting bonded devices: $e");
    }

    if (mounted) {
      setState(() {
        _devices = devices;
        _connected = isConnected ?? false;
      });
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            _isLoading = false;
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            _isLoading = false;
          });
          break;
        default:
          break;
      }
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    if (statuses[Permission.bluetoothConnect]!.isGranted) {
      _getDevices();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluetooth permissions are required to scan for printers.")),
        );
      }
    }
  }

  void _getDevices() async {
    setState(() => _isLoading = true);
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _connect() {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a device first")),
      );
      return;
    }

    setState(() => _isLoading = true);
    bluetooth.connect(_selectedDevice!).catchError((error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not connect: $error")),
        );
      }
    });
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  void _testPrint() async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected == true) {
      bluetooth.printCustom("K-BEAUTY HOUSE", 3, 1);
      bluetooth.printCustom("Bluetooth Printer Test", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printNewLine();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Printer is not connected")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Thermal Printer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure your printer is turned on and paired with your phone bluetooth settings.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<BluetoothDevice>(
                    isExpanded: true,
                    hint: const Text('Select Device'),
                    value: _selectedDevice,
                    items: _devices.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text(device.name ?? 'Unknown Device'),
                      );
                    }).toList(),
                    onChanged: (device) {
                      setState(() => _selectedDevice = device);
                    },
                  ),
                ),
                IconButton(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Scan Devices',
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _connected ? _disconnect : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _connected ? Colors.red : AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_connected ? 'DISCONNECT' : 'CONNECT'),
                ),
              ),
              if (_connected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('TEST PRINT'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _connected 
                        ? 'Printer is connected and ready to use.' 
                        : 'Please pair your thermal printer in your phone\'s Bluetooth settings first, then select it here.',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

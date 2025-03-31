import 'package:libserialport/libserialport.dart';

List<String> get availableSerialPort => SerialPort.availablePorts;
String get defaultSerialPort => SerialPort.availablePorts.first;
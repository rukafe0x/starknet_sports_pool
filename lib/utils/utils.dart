import 'package:starknet/starknet.dart';

/// Converts a single Felt to an ASCII string
String feltToAsciiString(Felt felt) {
  BigInt value = felt.toBigInt();
  List<int> bytes = [];

  // Extract ASCII characters from the felt value
  // Each ASCII character is 1 byte (8 bits)
  while (value > BigInt.zero) {
    // Extract the lowest 8 bits (1 byte)
    int charCode = (value & BigInt.from(0xFF)).toInt();
    if (charCode > 0) {
      bytes.add(charCode);
    }
    // Shift right by 8 bits
    value = value >> 8;
  }

  // Reverse the bytes since we extracted them in reverse order
  bytes = bytes.reversed.toList();

  // Convert the byte array to a string
  return String.fromCharCodes(bytes);
}

/// Converts a list of Felts to a single ASCII string
/// Useful when a string is split across multiple felts
String feltsToAsciiString(List<Felt> felts) {
  StringBuffer buffer = StringBuffer();

  for (var felt in felts) {
    buffer.write(feltToAsciiString(felt));
  }

  return buffer.toString();
}

// Helper method to decode hex string to human readable format
String decodeHexString(String hexString) {
  if (!hexString.startsWith('0x')) {
    return hexString;
  }

  try {
    // Remove '0x' prefix
    final cleanHex = hexString.substring(2);

    // Convert hex to bytes
    final bytes = <int>[];
    for (var i = 0; i < cleanHex.length; i += 2) {
      if (i + 2 <= cleanHex.length) {
        bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
      }
    }

    // Convert bytes to string
    return String.fromCharCodes(bytes);
  } catch (e) {
    return hexString;
  }
}

// Helper method to parse hex value to double
double parseHexToDouble(dynamic hexValue) {
  if (hexValue == null) return 0.0;

  try {
    final hexString = hexValue.toString();
    if (hexString.startsWith('0x')) {
      return int.parse(hexString.substring(2), radix: 16).toDouble();
    }
    return double.tryParse(hexString) ?? 0.0;
  } catch (e) {
    return 0.0;
  }
}

import 'package:starknet/starknet.dart';

/// Converts a single Felt to an ASCII string
String feltToAsciiString(Felt? felt) {
  if (felt == null) return '';
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

String uint256ToStrkString(Uint256 amount) {
  // Convert the Uint256 to BigInt
  final bigAmount = (BigInt.from(amount.high.toInt()) << 128) |
      BigInt.from(amount.low.toInt());

  // Convert to string with 18 decimals
  final strAmount = bigAmount.toString();

  if (strAmount.length <= 18) {
    // If the number is smaller than 18 decimals, pad with zeros
    final padded = strAmount.padLeft(18, '0');
    final trimmed = padded.replaceAll(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? '0' : '0.$trimmed';
  } else {
    // Split the number at the decimal point
    final decimalPart = strAmount.substring(strAmount.length - 18);
    final wholePart = strAmount.substring(0, strAmount.length - 18);

    // If decimal part is all zeros, just return the whole part
    if (BigInt.parse(decimalPart) == BigInt.zero) {
      return wholePart;
    }

    // Remove trailing zeros from decimal part
    final trimmedDecimal = decimalPart.replaceAll(RegExp(r'0+$'), '');
    return trimmedDecimal.isEmpty ? wholePart : '$wholePart.$trimmedDecimal';
  }
}

Uint256 strkToUint256(String strkAmount) {
  // Split the input into whole and decimal parts
  final parts = strkAmount.split('.');
  final wholePart = parts[0];
  final decimalPart = parts.length > 1 ? parts[1] : '';

  // Convert to BigInt with 18 decimals
  final decimalPlaces = 18;
  final paddedDecimal = decimalPart.padRight(decimalPlaces, '0');
  final bigAmount = BigInt.parse(wholePart + paddedDecimal);

  // Convert to Uint256 (low and high)
  final low = Felt(bigAmount & ((BigInt.one << 128) - BigInt.one));
  final high = Felt(bigAmount >> 128);

  return Uint256(low: low, high: high);
}

String formatStrkBalance(Uint256 balance, {int decimals = 4}) {
  final bigInt = balance.toBigInt();
  final divisor = BigInt.from(10).pow(18);
  final whole = bigInt ~/ divisor;
  final fraction =
      (bigInt % divisor).toString().padLeft(18, '0').substring(0, decimals);
  return '$whole.$fraction';
}

String formatTokenBalance(Uint256 balance,
    {int decimals = 18, int displayDecimals = 18}) {
  final bigInt = balance.toBigInt();
  final divisor = BigInt.from(10).pow(decimals);
  final whole = bigInt ~/ divisor;
  final fraction = (bigInt % divisor)
      .toString()
      .padLeft(decimals, '0')
      .substring(0, displayDecimals)
      .replaceAll(RegExp(r'0+$'), '');
  return fraction.isEmpty ? '$whole' : '$whole.$fraction';
}

BigInt parseTokenAmount(String value, {int decimals = 18}) {
  final parts = value.split('.');
  final whole = parts[0];
  final fraction = parts.length > 1 ? parts[1] : '';
  final paddedFraction =
      fraction.padRight(decimals, '0').substring(0, decimals);
  return BigInt.parse(whole + paddedFraction);
}

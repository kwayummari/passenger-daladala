// lib/core/utils/phone_number_formatter.dart
import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    // Remove any non-digit characters
    final digitsOnly = newText.replaceAll(RegExp(r'[^0-9]'), '');

    // Ensure it starts with 07
    String formattedText = digitsOnly;
    if (digitsOnly.isNotEmpty && !digitsOnly.startsWith('07')) {
      if (digitsOnly.startsWith('7')) {
        formattedText = '0$digitsOnly';
      } else if (digitsOnly.startsWith('255')) {
        // Convert from international format
        formattedText = '0${digitsOnly.substring(3)}';
      } else {
        // If it doesn't start with 0 or 7, prepend 07
        formattedText = '07$digitsOnly';
      }
    }

    // Limit to 10 digits
    if (formattedText.length > 10) {
      formattedText = formattedText.substring(0, 10);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class PhoneNumberUtils {
  /// Validates Tanzanian phone number
  static bool isValidTanzanianPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Should be 10 digits starting with 07
    if (cleanPhone.length == 10 && cleanPhone.startsWith('07')) {
      return true;
    }

    // Should be 12 digits starting with 255
    if (cleanPhone.length == 12 && cleanPhone.startsWith('255')) {
      return true;
    }

    return false;
  }

  /// Formats phone number to 07XXXXXXXX format
  static String formatToLocal(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.startsWith('255')) {
      return '0${cleanPhone.substring(3)}';
    } else if (cleanPhone.startsWith('07')) {
      return cleanPhone;
    } else if (cleanPhone.startsWith('7')) {
      return '0$cleanPhone';
    }

    return cleanPhone;
  }

  /// Formats phone number to international format (+255XXXXXXXXX)
  static String formatToInternational(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.startsWith('07')) {
      return '+255${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('255')) {
      return '+$cleanPhone';
    } else if (cleanPhone.startsWith('7')) {
      return '+255$cleanPhone';
    }

    return phone;
  }

  /// Detects mobile money provider based on phone number
  static String? detectProvider(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length < 3) return null;

    // Get the network prefix (first 3 digits after country code)
    String prefix;
    if (cleanPhone.startsWith('255')) {
      if (cleanPhone.length < 6) return null;
      prefix = cleanPhone.substring(3, 6);
    } else if (cleanPhone.startsWith('07')) {
      if (cleanPhone.length < 5) return null;
      prefix = cleanPhone.substring(2, 5);
    } else {
      return null;
    }

    // Vodacom (M-Pesa) prefixes
    if (['754', '755', '756', '757', '758', '759'].contains(prefix)) {
      return 'M-Pesa';
    }

    // Tigo prefixes
    if (['714', '715', '716', '717', '718', '719'].contains(prefix)) {
      return 'Tigo Pesa';
    }

    // Airtel prefixes
    if (['744', '745', '746', '747', '748', '749'].contains(prefix)) {
      return 'Airtel Money';
    }

    // Halotel prefixes
    if (['777', '778', '779'].contains(prefix)) {
      return 'HaloPesa';
    }

    return 'Mobile Money';
  }

  /// Gets provider icon based on detected provider
  static String getProviderIcon(String? provider) {
    switch (provider) {
      case 'M-Pesa':
        return '💚'; // Or use actual M-Pesa icon
      case 'Tigo Pesa':
        return '🔵'; // Or use actual Tigo icon
      case 'Airtel Money':
        return '🔴'; // Or use actual Airtel icon
      case 'HaloPesa':
        return '🟡'; // Or use actual Halotel icon
      default:
        return '📱';
    }
  }

  /// Gets provider color based on detected provider
  static String getProviderColor(String? provider) {
    switch (provider) {
      case 'M-Pesa':
        return '#00A651'; // M-Pesa green
      case 'Tigo Pesa':
        return '#0066CC'; // Tigo blue
      case 'Airtel Money':
        return '#FF0000'; // Airtel red
      case 'HaloPesa':
        return '#FFD700'; // Halotel gold
      default:
        return '#666666'; // Default gray
    }
  }

  /// Masks phone number for display (e.g., 0744****858)
  static String maskPhoneNumber(String phone) {
    final cleanPhone = formatToLocal(phone);

    if (cleanPhone.length >= 10) {
      return '${cleanPhone.substring(0, 4)}****${cleanPhone.substring(7)}';
    }

    return cleanPhone;
  }

  /// Validates and cleans phone number for API submission
  static String? cleanForSubmission(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (isValidTanzanianPhone(cleanPhone)) {
      return formatToLocal(cleanPhone);
    }

    return null;
  }
}

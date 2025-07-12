class Validators {
  Validators._();

  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Tanzania phone format: +255XXXXXXXXX or 0XXXXXXXXX
    final RegExp tanzaniaPhoneRegex = RegExp(
      r'^(?:\+255|0)[67]\d{8}$',
    );
    
    if (!tanzaniaPhoneRegex.hasMatch(value)) {
      return 'Enter a valid Tanzania phone number';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }


  static String? validateNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    
    if (int.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    
    return null;
  }
  
  static String? validateNumberRange(
    String? value, {
    String? fieldName,
    int? min,
    int? max,
  }) {
    final baseValidation = validateNumber(value, fieldName: fieldName);
    if (baseValidation != null) {
      return baseValidation;
    }
    
    final number = int.parse(value!);
    
    if (min != null && number < min) {
      return '${fieldName ?? 'Value'} must be at least $min';
    }
    
    if (max != null && number > max) {
      return '${fieldName ?? 'Value'} must be at most $max';
    }
    
    return null;
  }

  static String? validateTanzanianPhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (!RegExp(r'^(255|0)[67]\d{8}$').hasMatch(cleanPhone)) {
      return 'Please enter a valid Tanzanian phone number';
    }
    return null;
  }
}
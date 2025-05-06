import 'package:flutter/material.dart';

/// Utility class for email validation with specific rules for company emails
class EmailValidator {
  /// List of common personal email domains
  static const List<String> _commonPersonalDomains = [
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'aol.com',
    'icloud.com',
    'protonmail.com',
    'zoho.com',
    'mail.com',
    'yandex.com'
  ];

  /// List of Palestinian domains
  static const List<String> _palestinianDomains = [
    'palestine.ps',
    'palestine.com',
    'palestine.net',
    'pal.ps',
    'pal.com',
    'pal.net',
    'palestinian.ps',
    'palestinian.com',
    'palestinian.net',
    'gaza.ps',
    'gaza.com',
    'gaza.net',
    'ramallah.ps',
    'ramallah.com',
    'ramallah.net',
    'bethlehem.ps',
    'bethlehem.com',
    'bethlehem.net',
    'jerusalem.ps',
    'jerusalem.com',
    'jerusalem.net',
    'nablus.ps',
    'nablus.com',
    'nablus.net',
    'hebron.ps',
    'hebron.com',
    'hebron.net',
    'pna.ps',
    'pna.com',
    'pna.net',
    'plo.ps',
    'plo.com',
    'plo.net',
    'pa.ps',
    'pa.com',
    'pa.net'
  ];

  /// List of company-related terms
  static const List<String> _companyTerms = [
    'company',
    'corp',
    'inc',
    'ltd',
    'llc',
    'enterprise',
    'business',
    'org',
    'co'
  ];

  /// Basic email format validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  /// Validates if the email is a company email
  static bool isCompanyEmail(String email) {
    if (email.isEmpty) return false;
    if (!_emailRegex.hasMatch(email)) return false;

    final domain = email.split('@')[1].toLowerCase();
    return !_commonPersonalDomains.contains(domain);
  }

  /// Validates company email with Palestinian domain requirements
  static String? validateCompanyEmail(String? value, String userType) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (userType != 'Company') {
      return null;
    }

    if (!_emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    final parts = value.split('@');
    if (parts.length != 2) {
      return 'Invalid email format';
    }

    final username = parts[0].toLowerCase();
    final domain = parts[1].toLowerCase();

    if (!_palestinianDomains.any((d) => domain.endsWith(d))) {
      return 'Company users must use a Palestinian company email domain';
    }

    if (!_companyTerms.any((term) => username.contains(term))) {
      return 'Company email username should contain company-related terms (e.g., company, corp, inc)';
    }

    if (value.length > 254) {
      return 'Email address is too long';
    }

    return null;
  }

  /// Gets suggestions for company email domains based on partial input
  static List<String> getCompanyDomainSuggestions(String partialDomain) {
    if (partialDomain.isEmpty) return [];

    return _commonPersonalDomains
        .where((domain) => domain.contains(partialDomain.toLowerCase()))
        .toList();
  }
}

import 'package:flutter/material.dart';
import '../../utils/email_validator.dart';

class EmailValidator {
  // List of common company email domains
  static const List<String> _commonCompanyDomains = [
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

  // List of Palestinian domains
  static final List<String> palestinianDomains = [
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

  // List of company-related terms
  static final List<String> companyTerms = [
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

  // Validate if the email is a company email
  static bool isCompanyEmail(String email) {
    if (email.isEmpty) return false;

    // Basic email format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    if (!emailRegex.hasMatch(email)) return false;

    // Extract domain from email
    final domain = email.split('@')[1].toLowerCase();

    // Check if the domain is not in the list of common personal email domains
    return !_commonCompanyDomains.contains(domain);
  }

  // Get validation message for the email
  static String? getValidationMessage(String email) {
    if (email.isEmpty) {
      return 'Please enter an email address';
    }

    if (!isCompanyEmail(email)) {
      return 'Please use your company email address';
    }

    return null;
  }

  // Validate email and return error message if invalid
  static String? validateEmail(String email) {
    final message = getValidationMessage(email);
    if (message != null) {
      return message;
    }
    return null;
  }

  // Check if email is valid for company registration
  static bool isValidForCompanyRegistration(String email) {
    return isCompanyEmail(email);
  }

  // Get suggestions for company email domains
  static List<String> getCompanyDomainSuggestions(String partialDomain) {
    if (partialDomain.isEmpty) return [];

    return _commonCompanyDomains
        .where((domain) => domain.contains(partialDomain.toLowerCase()))
        .toList();
  }

  // Validate company email with Palestinian domain requirements
  static String? validateCompanyEmail(String? value, String userType) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (userType != 'Company') {
      return null; // No special validation for non-company users
    }

    // Check email format
    if (!value.contains('@')) {
      return 'Invalid email format';
    }

    final parts = value.split('@');
    if (parts.length != 2) {
      return 'Invalid email format';
    }

    final username = parts[0].toLowerCase();
    final domain = parts[1].toLowerCase();

    // Check domain
    if (!palestinianDomains.any((d) => domain.endsWith(d))) {
      return 'Company users must use a Palestinian company email domain';
    }

    // Check for company terms in username
    if (!companyTerms.any((term) => username.contains(term))) {
      return 'Company email username should contain company-related terms (e.g., company, corp, inc)';
    }

    // Check email length
    if (value.length > 254) {
      return 'Email address is too long';
    }

    return null;
  }
}

class Language {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'groups': 'Groups',
      'my_groups': 'My Groups',
      'available_groups': 'Available Groups',
      'no_my_groups': 'You are not a member of any groups yet',
      'no_available_groups': 'No available groups to join',
      'home': 'Home',
      'ai': 'AI',
      'profile': 'Profile',
      'no_groups_hint': 'Join or create a group to get started',
    },
    'ar': {
      'groups': 'المجموعات',
      'my_groups': 'مجموعاتي',
      'available_groups': 'المجموعات المتاحة',
      'no_my_groups': 'أنت لست عضواً في أي مجموعة بعد',
      'no_available_groups': 'لا توجد مجموعات متاحة للانضمام',
      'home': 'الرئيسية',
      'ai': 'الذكاء الاصطناعي',
      'profile': 'الملف الشخصي',
      'no_groups_hint': 'انضم أو أنشئ مجموعة للبدء',
    },
  };

  static String _currentLanguage = 'en';

  static void setLanguage(String language) {
    if (_translations.containsKey(language)) {
      _currentLanguage = language;
    }
  }

  static String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }
}

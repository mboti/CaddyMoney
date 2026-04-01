class AppConstants {
  static const String appName = 'CaddyMoney';
  static const String defaultCurrency = 'EUR';
  static const String defaultLanguage = 'fr';
  static const String fallbackLanguage = 'en';

  /// Countries shown across the app in country/nationality selectors.
  ///
  /// Keep this list in sync wherever we offer a country picker.
  static const List<String> countryOptions = [
    'Morocco',
    'Algeria',
    'Tunisia',
    'Spain',
    'Italy',
    'Belgium',
    'France',
    'Germany',
    'Switzerland',
    'England',
    'Other',
  ];
  
  static const List<String> supportedLanguages = [
    'fr',
    'en',
    'es',
    'de',
    'it',
    'ar',
  ];

  static const List<String> supportedCurrencies = [
    'EUR',
    'USD',
    'GBP',
  ];

  static const List<String> businessCategories = [
    'Retail',
    'Food & Beverage',
    'Services',
    'Technology',
    'Healthcare',
    'Education',
    'Entertainment',
    'Transportation',
    'Real Estate',
    'Other',
  ];

  /// Business types shown in merchant onboarding.
  ///
  /// Keys are normalized country names (lowercase, no accents). See
  /// `MerchantOnboardingKycScreen._normalizeCountryKey`.
  static const Map<String, List<String>> businessTypesByCountry = {
    // France
    'france': [
      'Micro-entreprise / Auto-entrepreneur',
      'Entreprise individuelle (EI)',
      'EURL',
      'SARL',
      'SAS',
      'SASU',
      'SA',
      'SNC',
      'SCI',
      'Association',
      'Autre',
    ],

    // Morocco
    'morocco': ['Auto-entrepreneur', 'SARL', 'SARL AU', 'SA', 'SNC', 'SCA', 'GIE', 'Autre'],
    'maroc': ['Auto-entrepreneur', 'SARL', 'SARL AU', 'SA', 'SNC', 'SCA', 'GIE', 'Autre'],

    // Algeria
    'algeria': ['EURL', 'SARL', 'SPA', 'SNC', 'SCS', 'Autre'],
    'algerie': ['EURL', 'SARL', 'SPA', 'SNC', 'SCS', 'Autre'],

    // Tunisia
    'tunisia': ['Personne physique (PP)', 'SUARL', 'SARL', 'SA', 'SNC', 'SCA', 'Autre'],
    'tunisie': ['Personne physique (PP)', 'SUARL', 'SARL', 'SA', 'SNC', 'SCA', 'Autre'],
  };
}

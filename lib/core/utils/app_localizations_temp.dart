import 'package:flutter/material.dart';

/// Temporary localizations until flutter gen-l10n generates the real ones
/// This file will be replaced by the generated AppLocalizations
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // French translations (default)
  static final Map<String, String> _frStrings = {
    'appName': 'CaddyMoney',
    'welcomeBack': 'Bienvenue',
    'signIn': 'Se connecter',
    'signUp': 'S\'inscrire',
    'signOut': 'Se déconnecter',
    'email': 'Email',
    'password': 'Mot de passe',
    'confirmPassword': 'Confirmer le mot de passe',
    'forgotPassword': 'Mot de passe oublié?',
    'dontHaveAccount': 'Pas de compte?',
    'alreadyHaveAccount': 'Déjà un compte?',
    'roleSelectionTitle': 'Sélectionnez votre rôle',
    'roleSelectionSubtitle': 'Choisissez comment utiliser CaddyMoney',
    'userRole': 'Je suis utilisateur',
    'userRoleDesc': 'Envoyer et recevoir de l\'argent',
    'merchantRole': 'Je suis commerçant',
    'merchantRoleDesc': 'Enregistrez votre entreprise et recevez des paiements',
    'adminRole': 'Je gère la plateforme',
    'adminRoleDesc': 'Gérer les utilisateurs, commerçants et transactions',
    'balance': 'Solde',
    'send': 'Envoyer',
    'receive': 'Recevoir',
    'transactions': 'Transactions',
    'profile': 'Profil',
    'settings': 'Paramètres',
    'sendMoney': 'Envoyer de l\'argent',
    'receiveMoney': 'Recevoir de l\'argent',
    'recipient': 'Destinataire',
    'amount': 'Montant',
    'note': 'Note',
    'optional': 'Optionnel',
    'businessName': 'Nom de l\'entreprise',
    'ownerName': 'Nom du propriétaire',
    'phone': 'Téléphone',
    'address': 'Adresse',
    'city': 'Ville',
    'country': 'Pays',
    'category': 'Catégorie',
    'pending': 'En attente',
    'approved': 'Approuvé',
    'rejected': 'Rejeté',
    'suspended': 'Suspendu',
    'active': 'Actif',
    'users': 'Utilisateurs',
    'merchants': 'Commerçants',
    'dashboard': 'Tableau de bord',
    'totalUsers': 'Total utilisateurs',
    'totalMerchants': 'Total commerçants',
    'totalTransactions': 'Total transactions',
    'transactionVolume': 'Volume des transactions',
    'language': 'Langue',
    'version': 'Version',
    'success': 'Succès',
    'error': 'Erreur',
    'loading': 'Chargement...',
    'submit': 'Soumettre',
    'cancel': 'Annuler',
    'confirm': 'Confirmer',
    'delete': 'Supprimer',
    'edit': 'Modifier',
    'save': 'Enregistrer',
    'requiredField': 'Ce champ est requis',
    'invalidEmail': 'Adresse e-mail invalide',
    'passwordTooShort': 'Le mot de passe doit contenir au moins 8 caractères',
    'passwordsDoNotMatch': 'Les mots de passe ne correspondent pas',
    'invalidAmount': 'Veuillez saisir un montant valide',
  };
  
  // English translations
  static final Map<String, String> _enStrings = {
    'appName': 'CaddyMoney',
    'welcomeBack': 'Welcome Back',
    'signIn': 'Sign In',
    'signUp': 'Sign Up',
    'signOut': 'Sign Out',
    'email': 'Email',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'forgotPassword': 'Forgot Password?',
    'dontHaveAccount': 'Don\'t have an account?',
    'alreadyHaveAccount': 'Already have an account?',
    'roleSelectionTitle': 'Select Your Role',
    'roleSelectionSubtitle': 'Choose how you want to use CaddyMoney',
    'userRole': 'I am a user',
    'userRoleDesc': 'Send and receive money',
    'merchantRole': 'I am a merchant',
    'merchantRoleDesc': 'Register your business and receive payments',
    'adminRole': 'I manage the platform',
    'adminRoleDesc': 'Manage users, merchants, and transactions',
    'balance': 'Balance',
    'send': 'Send',
    'receive': 'Receive',
    'transactions': 'Transactions',
    'profile': 'Profile',
    'settings': 'Settings',
    'sendMoney': 'Send Money',
    'receiveMoney': 'Receive Money',
    'recipient': 'Recipient',
    'amount': 'Amount',
    'note': 'Note',
    'optional': 'Optional',
    'businessName': 'Business Name',
    'ownerName': 'Owner Name',
    'phone': 'Phone',
    'address': 'Address',
    'city': 'City',
    'country': 'Country',
    'category': 'Category',
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'suspended': 'Suspended',
    'active': 'Active',
    'users': 'Users',
    'merchants': 'Merchants',
    'dashboard': 'Dashboard',
    'totalUsers': 'Total Users',
    'totalMerchants': 'Total Merchants',
    'totalTransactions': 'Total Transactions',
    'transactionVolume': 'Transaction Volume',
    'language': 'Language',
    'version': 'Version',
    'success': 'Success',
    'error': 'Error',
    'loading': 'Loading...',
    'submit': 'Submit',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'delete': 'Delete',
    'edit': 'Edit',
    'save': 'Save',
    'requiredField': 'This field is required',
    'invalidEmail': 'Invalid email address',
    'passwordTooShort': 'Password must be at least 8 characters',
    'passwordsDoNotMatch': 'Passwords do not match',
    'invalidAmount': 'Please enter a valid amount',
  };
  
  Map<String, String> get _strings {
    switch (locale.languageCode) {
      case 'en':
        return _enStrings;
      case 'fr':
      default:
        return _frStrings;
    }
  }
  
  String get appName => _strings['appName']!;
  String get welcomeBack => _strings['welcomeBack']!;
  String get signIn => _strings['signIn']!;
  String get signUp => _strings['signUp']!;
  String get signOut => _strings['signOut']!;
  String get email => _strings['email']!;
  String get password => _strings['password']!;
  String get confirmPassword => _strings['confirmPassword']!;
  String get forgotPassword => _strings['forgotPassword']!;
  String get dontHaveAccount => _strings['dontHaveAccount']!;
  String get alreadyHaveAccount => _strings['alreadyHaveAccount']!;
  String get roleSelectionTitle => _strings['roleSelectionTitle']!;
  String get roleSelectionSubtitle => _strings['roleSelectionSubtitle']!;
  String get userRole => _strings['userRole']!;
  String get userRoleDesc => _strings['userRoleDesc']!;
  String get merchantRole => _strings['merchantRole']!;
  String get merchantRoleDesc => _strings['merchantRoleDesc']!;
  String get adminRole => _strings['adminRole']!;
  String get adminRoleDesc => _strings['adminRoleDesc']!;
  String get balance => _strings['balance']!;
  String get send => _strings['send']!;
  String get receive => _strings['receive']!;
  String get transactions => _strings['transactions']!;
  String get profile => _strings['profile']!;
  String get settings => _strings['settings']!;
  String get sendMoney => _strings['sendMoney']!;
  String get receiveMoney => _strings['receiveMoney']!;
  String get recipient => _strings['recipient']!;
  String get amount => _strings['amount']!;
  String get note => _strings['note']!;
  String get optional => _strings['optional']!;
  String get businessName => _strings['businessName']!;
  String get ownerName => _strings['ownerName']!;
  String get phone => _strings['phone']!;
  String get address => _strings['address']!;
  String get city => _strings['city']!;
  String get country => _strings['country']!;
  String get category => _strings['category']!;
  String get pending => _strings['pending']!;
  String get approved => _strings['approved']!;
  String get rejected => _strings['rejected']!;
  String get suspended => _strings['suspended']!;
  String get active => _strings['active']!;
  String get users => _strings['users']!;
  String get merchants => _strings['merchants']!;
  String get dashboard => _strings['dashboard']!;
  String get totalUsers => _strings['totalUsers']!;
  String get totalMerchants => _strings['totalMerchants']!;
  String get totalTransactions => _strings['totalTransactions']!;
  String get transactionVolume => _strings['transactionVolume']!;
  String get language => _strings['language']!;
  String get version => _strings['version']!;
  String get success => _strings['success']!;
  String get error => _strings['error']!;
  String get loading => _strings['loading']!;
  String get submit => _strings['submit']!;
  String get cancel => _strings['cancel']!;
  String get confirm => _strings['confirm']!;
  String get delete => _strings['delete']!;
  String get edit => _strings['edit']!;
  String get save => _strings['save']!;
  String get requiredField => _strings['requiredField']!;
  String get invalidEmail => _strings['invalidEmail']!;
  String get passwordTooShort => _strings['passwordTooShort']!;
  String get passwordsDoNotMatch => _strings['passwordsDoNotMatch']!;
  String get invalidAmount => _strings['invalidAmount']!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en', 'es', 'de', 'it', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

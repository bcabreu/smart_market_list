// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSystem => 'System Default';

  @override
  String get darkModeLight => 'Light';

  @override
  String get darkModeDark => 'Dark';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Promotion alerts';

  @override
  String get language => 'Language';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get shareList => 'Share List';

  @override
  String get shareListSubtitle => 'Sync with family';

  @override
  String get expenseCharts => 'Expense Charts';

  @override
  String get expenseChartsSubtitle => 'Full monthly analysis';

  @override
  String get exportReports => 'Export Reports';

  @override
  String get exportReportsSubtitle => 'PDF with history';

  @override
  String get account => 'Account';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get privacy => 'Privacy';

  @override
  String get logout => 'Log Out';

  @override
  String get recipesTitle => 'Recipes for You 👨‍🍳';

  @override
  String get recipesSubtitle => 'Based on your ingredients';

  @override
  String get searchHint => 'Search recipe';

  @override
  String get recipesFound => 'Recipes Found';

  @override
  String get youCanCookNow => 'You Can Cook Now';

  @override
  String get youCanCookNowSubtitle =>
      'Recipes with ingredients you already have';

  @override
  String get otherRecipes => 'Other Recipes';

  @override
  String get otherRecipesSubtitle =>
      'Discover new recipes and add ingredients to your list';

  @override
  String get cookTime => 'min';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get instructions => 'Instructions';

  @override
  String get navShop => 'Shop';

  @override
  String get navNotes => 'Notes';

  @override
  String get navRecipes => 'Recipes';

  @override
  String get navProfile => 'Profile';

  @override
  String get noLists => 'No lists created';

  @override
  String get createList => 'Create List';

  @override
  String get addItem => 'Add Item';

  @override
  String get clearList => 'Clear List';

  @override
  String get share => 'Share';

  @override
  String get items => 'Items';

  @override
  String get emptyListTitle => 'Your list is empty';

  @override
  String get emptyListSubtitle => 'Add items to start shopping.';

  @override
  String get completedItems => 'Completed';

  @override
  String get restoreItemsTitle => 'Restore Items?';

  @override
  String get restoreItemsMessage =>
      'All completed items will be moved back to the shopping list.';

  @override
  String get clearCompletedTitle => 'Clear Completed?';

  @override
  String get clearCompletedMessage =>
      'All completed items will be permanently removed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get restore => 'Restore';

  @override
  String get clear => 'Clear';

  @override
  String get shoppingNotesTitle => 'Shopping Notes 🧾';

  @override
  String get shoppingNotesSubtitle => 'Spending history';

  @override
  String get totalSpent => 'Total spent';

  @override
  String get savedNotes => 'Saved notes';

  @override
  String get noSavedNotes => 'No saved notes';

  @override
  String get noSavedNotesSubtitle =>
      'Compare prices and save\nby saving your shopping receipts.';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get deleteNoteTitle => 'Delete Note?';

  @override
  String get deleteNoteMessage =>
      'Are you sure you want to delete this note permanently?';

  @override
  String get delete => 'Delete';

  @override
  String get profileTitle => 'Profile 👤';

  @override
  String get personalInfo => 'Your personal information';

  @override
  String get guest => 'Guest';

  @override
  String get favoriteRecipesStats => 'Favorite\nRecipes';

  @override
  String get savedNotesStats => 'Saved\nNotes';

  @override
  String get sharingListsStats => 'Sharing\nLists';

  @override
  String get editProfileSoon => 'Edit profile (Coming soon)';

  @override
  String get changePhoto => 'Change Profile Photo';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String imageError(Object error) {
    return 'Error selecting image: $error';
  }

  @override
  String get clientSince => 'Customer since';

  @override
  String get premiumLabel => 'Premium';
}

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
  String get premiumLabel => 'Premium';

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
  String matchesInList(Object count) {
    return '$count in list';
  }

  @override
  String missingIngredients(Object count) {
    return '$count missing';
  }

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get favoriteRecipesTitle => 'Favorite Recipes';

  @override
  String get noFavorites => 'No favorite recipes';

  @override
  String get noFavoritesSubtitle => 'Mark recipes with ❤️ to see them here';

  @override
  String get viewNote => 'View note';

  @override
  String get totalLabel => 'Total';

  @override
  String get newNoteTitle => 'New Note';

  @override
  String get newNoteSubtitle => 'Register your purchase';

  @override
  String get storeLabel => 'Store Name';

  @override
  String get storeHint => 'Ex: Central Supermarket';

  @override
  String get totalValueLabel => 'Total Value';

  @override
  String get requiredField => 'Required';

  @override
  String get notePhotoLabel => 'Note Photo (optional)';

  @override
  String get addPhotoHint => 'Take photo or choose from gallery';

  @override
  String get saveNoteButton => 'Save Note';

  @override
  String get generalPurchase => 'General Purchase';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get editItem => 'Edit Item';

  @override
  String get addItemTitle => 'Add Item';

  @override
  String get fillFields => 'Fill in the fields';

  @override
  String get itemName => 'Item Name';

  @override
  String get itemNameHint => 'Ex: Tomato, Bread, Milk...';

  @override
  String get suggestions => 'Suggestions (click to fill)';

  @override
  String get quantity => 'Quantity';

  @override
  String get quantityHint => 'Ex: 1kg, 2 liters, 500g...';

  @override
  String get priceOptional => 'Price (optional)';

  @override
  String get category => 'Category';

  @override
  String get newCategoryName => 'New category name';

  @override
  String get createCategory => 'Create new category';

  @override
  String get productPhotoOptional => 'Product Photo (optional)';

  @override
  String get takePhotoOrGallery => 'Take photo or choose from gallery';

  @override
  String get confirm => 'Confirm';

  @override
  String get currentTotal => 'Current Total';

  @override
  String get budgetLimit => 'Limit';

  @override
  String get allCategories => 'All categories';

  @override
  String itemsRemaining(Object count) {
    return '$count items remaining';
  }

  @override
  String get cat_hortifruti => 'Produce';

  @override
  String get cat_padaria => 'Bakery';

  @override
  String get cat_laticinios => 'Dairy';

  @override
  String get cat_acougue => 'Meat & Fish';

  @override
  String get cat_mercearia => 'Grocery';

  @override
  String get cat_bebidas => 'Drinks';

  @override
  String get cat_limpeza => 'Cleaning';

  @override
  String get cat_higiene => 'Hygiene';

  @override
  String get cat_congelados => 'Frozen';

  @override
  String get cat_doces => 'Sweets';

  @override
  String get cat_pet => 'Pet Shop';

  @override
  String get cat_bebe => 'Baby';

  @override
  String get cat_utilidades => 'Utilities';

  @override
  String get cat_outros => 'Others';

  @override
  String get renameList => 'Rename';

  @override
  String get duplicateList => 'Duplicate';

  @override
  String get deleteList => 'Delete';

  @override
  String get copySuffix => ' (Copy)';

  @override
  String get newList => 'New List';

  @override
  String get editList => 'Edit List';

  @override
  String get createPersonalizedList => 'Create a custom list';

  @override
  String get chooseEmoji => 'Choose an emoji';

  @override
  String get listName => 'List Name';

  @override
  String get listNameHint => 'Ex: Weekend BBQ';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createListButton => 'Create List';

  @override
  String get updateDetails => 'Update details';

  @override
  String get startPlanning => 'Start planning';

  @override
  String get login => 'Log In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get guestMessage => 'Save your data and access from anywhere';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'your@email.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Your secure password';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Your full name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginButton => 'Log In';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get welcomeBack => 'Welcome Back! 👋';

  @override
  String get welcomeBackSubtitle => 'We missed you';

  @override
  String get createAccountTitle => 'Create Account 🚀';

  @override
  String get createAccountSubtitle => 'Start your journey';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get shareEmailLabel => 'Share email';

  @override
  String get sharingWithLabel => 'Sharing with:';

  @override
  String get shareRealTimeInfo =>
      '✨ List changes are synchronized in real time';

  @override
  String get shareInviteMessage =>
      'Hello! I\'m inviting you to edit my shopping list on Smart Market List. Let\'s save together!';

  @override
  String get shareLimitReached => 'Limit reached (1/1)';

  @override
  String get shareLimitError => 'Only 1 person allowed in the current plan.';

  @override
  String get expenseChartsPeriod => 'Last 6 months';

  @override
  String get monthlyAverage => 'Monthly average:';

  @override
  String get totalSixMonths => 'Total (6 months):';

  @override
  String get goalLabel => 'Goal';

  @override
  String get editGoalTitle => 'Budget Goal';

  @override
  String get editGoalHint => 'Enter amount';

  @override
  String get statusWithinGoal => 'Within goal';

  @override
  String get statusOverBudget => 'Over budget';

  @override
  String get chartsDisclaimer => 'Values based on uploaded receipts';

  @override
  String get pdfReportTitle => 'Full Financial Report';

  @override
  String pdfGeneratedAt(Object date) {
    return 'Generated at $date';
  }

  @override
  String get pdfExecutiveSummary => 'Executive Summary';

  @override
  String get pdfTotalSpent => 'Total Spent (12m)';

  @override
  String get pdfMonthlyAverage => 'Monthly Average';

  @override
  String get pdfHighestSpending => 'Highest Spending';

  @override
  String get pdfAverageTicket => 'Average Ticket';

  @override
  String get pdfFinancialEvolution => 'Financial Evolution';

  @override
  String get pdfMonthlySummary => 'Monthly Summary (Goals vs. Spent)';

  @override
  String get pdfDetailedLogs => 'Detailed Shopping Logs';

  @override
  String get pdfMonth => 'Month';

  @override
  String get pdfGoal => 'Goal';

  @override
  String get pdfSpent => 'Spent';

  @override
  String get pdfStatus => 'Status';

  @override
  String get pdfItem => 'Item';

  @override
  String get pdfQty => 'Qty';

  @override
  String get pdfPrice => 'Price';

  @override
  String get pdfDiff => 'Diff';

  @override
  String get pdfStatusOver => 'Over Budget';

  @override
  String get pdfStatusOk => 'Within Goal';

  @override
  String get pdfPage => 'Page';

  @override
  String get pdfOf => 'of';
}

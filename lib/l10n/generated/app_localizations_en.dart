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
  String get shareList => 'Share App';

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

  @override
  String servings(Object count) {
    return '$count servings';
  }

  @override
  String get ingredientsInList => 'Ingredients in your list';

  @override
  String get missingIngredientsSectionTitle => 'Missing ingredients';

  @override
  String addItemsToList(Object count) {
    return 'Add $count items to list';
  }

  @override
  String get instructionsTitle => 'Instructions';

  @override
  String get noListFound => 'No shopping list found!';

  @override
  String itemsAdded(Object count, Object listName) {
    return '$count ingredients added to list \"$listName\"!';
  }

  @override
  String errorAddingItems(Object error) {
    return 'Error adding items: $error';
  }

  @override
  String get restoringPurchases => 'Restoring purchases...';

  @override
  String get restoreSuccess =>
      'Request sent. If there are active purchases, they will be restored soon.';

  @override
  String get restoreError => 'Could not connect to the store.';

  @override
  String get subscriptionManagementError =>
      'Could not open subscription management.';

  @override
  String get requestSentTitle => 'Request Sent';

  @override
  String get connectionErrorTitle => 'Connection Error';

  @override
  String get errorTitle => 'Error';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get emailSubject => 'Smart Market List Support';

  @override
  String get faqHowToShare => 'How do I share a list?';

  @override
  String get faqHowToShareAnswer =>
      'Go to Profile > Share List to invite someone. You need to be Premium.';

  @override
  String get faqPremiumBenefits => 'What are Premium benefits?';

  @override
  String get faqPremiumBenefitsAnswer =>
      'No ads, cloud saved lists, unlimited lists, sharing, expense charts, and PDF reports.';

  @override
  String get faqRestore => 'How do I restore my purchase?';

  @override
  String get faqRestoreAnswer => 'Go to Profile > Restore Purchase.';

  @override
  String get logoutTitle => 'Log Out?';

  @override
  String get logoutMessage => 'Are you sure you want to log out?';

  @override
  String get confirmLogout => 'Log Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deleteAccountMessage =>
      'This action is irreversible. All your lists, notes, and data will be permanently deleted.';

  @override
  String get confirmDelete => 'Delete Forever';

  @override
  String get processing => 'Processing...';

  @override
  String uploadError(Object error) {
    return 'Upload failed: $error';
  }

  @override
  String get processingUpload => 'Uploading photo...';

  @override
  String get appVersion => 'App Version';

  @override
  String get privacyPolicyText =>
      'Last updated: 12/07/2025\n\nYour privacy is important to us. It is Smart Market List\'s policy (hereinafter referred to as \"App\", \"We\" or \"Our\") to respect your privacy regarding any information we may collect from you.\n\nBy downloading and using our App, you agree to the collection and use of information in accordance with this policy.\n\n1. Information We Collect\nTo maximize the utility of the App and provide a personalized experience, we collect the following types of data:\n\n1.1. Personal Data (Registration)\nWhen creating an account or subscribing to our Premium services, we may ask for personally identifiable information, including but not limited to:\n• Full name: For profile personalization.\n• Email address: For login, password recovery, and important service communications.\n• Photos/Images: We collect photos only if you choose to upload them (e.g., profile picture or product/receipt scanning). Access to camera/gallery is requested only at the time of use.\n\n1.2. Location Data\nWe collect precise or approximate location data from your device.\n• Purpose: We use location to offer features like price comparison and display relevant ads.\n• Control: Collection occurs only if you grant explicit permission. You can revoke this permission at any time.\n\n1.3. Usage and Device Data\nWe automatically collect information on how you interact with the app, device model, operating system, unique advertising identifiers (like Google Advertising ID or IDFA), and crash reports.\n\n2. How We Use Your Information\nWe use collected data to:\n• Provide and maintain the service (e.g., saving lists to the cloud).\n• Process subscription payments.\n• Improve our algorithms.\n• Display Advertising: We use location and profile data to show third-party ads.\n\n3. Advertising and Third Parties\nTo keep the free version of the app, we display ads. We share non-personally identifiable data (like advertising ID) with partner ad networks (e.g., Google AdMob, Facebook Audience Network).\n\n4. Subscriptions and Payments\nAll financial transactions are processed directly by app stores (Google Play or App Store). We do not store your full credit card details.\n\n5. Storage and Security\nYour data is stored on secure servers (e.g., Firebase, AWS) and we adopt measures to protect it.\n\n6. Your Rights (GDPR/LGPD)\nYou have the right to access, correct, and request deletion of your personal data at any time via the \"Settings\" menu or by contacting us.\n\n7. Data Retention\nWe will retain your information only for as long as necessary to fulfill the purposes described.\n\n8. Changes to This Policy\nWe may update our Privacy Policy periodically. We recommend reviewing this page regularly.\n\n9. Contact\nIf you have questions, please contact us:\nEmail: contato@kepoweb.com\nData Controller: KepoWeb';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordDescription =>
      'Enter your email to receive a reset link.';

  @override
  String get sendLink => 'Send Link';

  @override
  String get resetLinkSent => 'Link Sent';

  @override
  String get resetLinkSentMessage => 'Check your email to reset your password.';

  @override
  String get familyPlanTitle => 'Family Plan';

  @override
  String get familyPlanSubtitle => 'Share Premium with 1 person';

  @override
  String get inviteMember => 'Invite Member';

  @override
  String get memberEmailHint => 'Enter guest email';

  @override
  String get sendInvite => 'Send Invite';

  @override
  String get inviteSentTitle => 'Invite Sent!';

  @override
  String get inviteSentMessage =>
      'The invited person must log in with this email to activate Premium.';

  @override
  String get alreadyInFamily => 'You are already in a family.';

  @override
  String get leaveFamily => 'Leave Family';

  @override
  String get premiumActive => 'Premium Active';

  @override
  String get planOwner => 'Owner';

  @override
  String get planGuest => 'Guest';

  @override
  String get invalidCredentialsError => 'Invalid email or password';

  @override
  String get invalidEmailError => 'The email entered is invalid';

  @override
  String get success => 'Success';

  @override
  String get logoutTitleWarning => 'Warning: Data Loss';

  @override
  String get logoutMessageWarning =>
      'You are on the Free plan. Logging out will PERMANENTLY ERASE all your lists on this device. Do you want to continue?';

  @override
  String get familyPlanExclusiveFeature => 'Family Plan Exclusive Feature';

  @override
  String get familyPlanUpgradeDescription =>
      'With the Individual plan you have Premium access, but to share with someone you need the Family Plan.';

  @override
  String get upgradeToFamily => 'Upgrade to Family';

  @override
  String get welcomeToList => 'Shared list added! 🛒';

  @override
  String get welcomeToFamilyTitle => 'Congratulations! 🏠✨';

  @override
  String get welcomeToFamilyMessage =>
      'You are now part of the Premium Family!';

  @override
  String get premiumIndividualMessage =>
      'You are now Individual Premium! Enjoy all features.';

  @override
  String get awesome => 'Awesome! 🚀';

  @override
  String get purchaseErrorTitle => 'Purchase Error';

  @override
  String get purchaseErrorMessage =>
      'Could not complete purchase. Please try again or contact support.';

  @override
  String joinListError(Object error) {
    return 'Error joining list: $error';
  }

  @override
  String joinFamilyError(Object error) {
    return 'Error joining family: $error';
  }

  @override
  String accountDeletedError(Object error) {
    return 'Error deleting account: $error';
  }

  @override
  String reportGenerationError(Object error) {
    return 'Error generating report: $error';
  }

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get accountCreatedAndListAdded =>
      'Account created and shared list added!';

  @override
  String genericError(Object error) {
    return 'Error: $error';
  }

  @override
  String get successTitle => 'Success!';

  @override
  String get requiresRecentLogin =>
      'For your security, please log in again before deleting your account.';

  @override
  String get emailAlreadyInUse =>
      'This email is already in use by another account.';

  @override
  String get inviteInvalidOrExpired =>
      'This invite link is invalid or has already been used.';

  @override
  String get familyAlreadyHasMember => 'This family is full.';

  @override
  String get guestInviteTitle => 'Only Owner can invite';

  @override
  String get guestInviteMessage =>
      'As a family member, you have Premium access, but only the plan owner can add or remove people.';

  @override
  String get premiumFamilyTitle => 'Premium Family';

  @override
  String get shareAccessSubtitle => 'Share access with 1 person';

  @override
  String get inviteViaLink => 'Invite Family Member via Link';

  @override
  String inviteFamilyMessageBody(Object ownerName) {
    return '$ownerName invited you to join the family on Smart Market List!\n\nYou will get Premium access and shared lists.';
  }

  @override
  String get accessLinkLabel => '🔗 *Access Link:*';

  @override
  String get installAppAdvice =>
      '_(If it doesn\'t work, install the app first)_';

  @override
  String get androidLabel => '🤖 *Android:*';

  @override
  String get iosLabel => '🍎 *iOS:*';

  @override
  String shareListMessageTitle(Object listName) {
    return '🛒 *$listName*';
  }

  @override
  String get shareListMessageBody => 'Join my shared shopping list!';

  @override
  String get featureNoAds => 'No Ads (Clean browsing)';

  @override
  String get featureUnlimitedLists => 'Unlimited lists & items';

  @override
  String get featureAllBenefits => 'All Individual Plan benefits';

  @override
  String get featureAllBenefitsSubtitle => 'No ads, receipt scanning & more';

  @override
  String get featureRealTimeShare => 'Real-time Sharing';

  @override
  String get featureRealTimeShareSubtitle =>
      'Invite and edit lists with anyone';

  @override
  String get featureReceiptScanning => 'Receipt Import';

  @override
  String get featureReceiptScanningSubtitle => 'Scan and save your receipts';

  @override
  String get featureComparePrices => 'Compare prices between stores';

  @override
  String get featureCharts => 'Expense Charts';

  @override
  String get featureReports => 'Export Reports';

  @override
  String get featureFamilyShare => 'Share Subscription';

  @override
  String get featureAutoSync => 'Family synchronization';

  @override
  String get featurePremiumGuest => 'Guest becomes Premium too';

  @override
  String get featurePremiumGuestSubtitle =>
      'Invited person gets full access to all features';

  @override
  String get featureCloudBackup => 'Cloud Backup';

  @override
  String get featureCloudBackupSubtitle => 'Never lose your data';

  @override
  String get planAnnual => 'Annual';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planAnnualPrice => '\$ 19.99/year';

  @override
  String get planMonthlyPrice => '\$ 2.99';

  @override
  String get planFamilyAnnualPrice => '\$ 29.99/year';

  @override
  String get planFamilyMonthlyPrice => '\$ 4.99/month';

  @override
  String get planAnnualBreakdown => '\$ 1.66';

  @override
  String get planFamilyAnnualBreakdown => '\$ 2.50';

  @override
  String get planMonthlySubtitle => '\$ 2.99/mo';

  @override
  String get planFamilyMonthlySubtitle => '\$ 4.99/mo';

  @override
  String get planToggleIndividual => 'Individual';

  @override
  String get planToggleFamily => 'Family';

  @override
  String get taxRate => 'Tax Rate (%)';

  @override
  String get taxRateSubtitle => 'Add percentage to total (e.g. Sales Tax)';

  @override
  String get enterTaxRate => 'Enter percentage';

  @override
  String get taxIncluded => 'Tax included';

  @override
  String get planAnnualSubtitle => '\$ 1.66/mo';

  @override
  String get planFamilyAnnualSubtitle => '\$ 2.50/mo';

  @override
  String pricePerMonth(Object price) {
    return '$price / mo';
  }

  @override
  String savePercent(Object percent) {
    return 'Save $percent%';
  }

  @override
  String get billedMonthly => 'Billed monthly';

  @override
  String get billedAnnually => 'Billed annually';

  @override
  String get bestValue => 'Best Value';

  @override
  String get cancelAnytime => 'Cancel anytime';

  @override
  String get sevenDaysFree => '7 days free';

  @override
  String get continueFree => 'Continue with free plan';

  @override
  String get bePremium => 'Be Premium!';

  @override
  String get unlockResources => 'Unlock exclusive features to save more';

  @override
  String get exclusiveResources => 'Exclusive Features';

  @override
  String get chooseYourPlan => 'Choose your plan';

  @override
  String get saveYiarlyAmount => 'Save \$ 16.00 per year!';

  @override
  String get saveYiarlyAmountFamily => 'Save \$ 30.00 per year!';

  @override
  String subscribeButton(Object price) {
    return 'Subscribe for $price';
  }

  @override
  String shareRecipeMessage(Object recipeName) {
    return 'Check out this recipe for \"$recipeName\" on Smart Market List! 😋';
  }

  @override
  String get viewRecipe => 'View Recipe';

  @override
  String get tryFree7Days => '7 DAYS FREE';

  @override
  String get loginRequiredTitle => 'Login Required';

  @override
  String get loginRequiredMessage =>
      'Please log in to restore and sync your subscription.';

  @override
  String get yourFamilyMember => 'Your family member';

  @override
  String get inviteFamilyTitle => 'Family Invite';

  @override
  String errorSharing(Object error) {
    return 'Error sharing: $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Error loading profile: $error';
  }

  @override
  String get youNeedToCreateFamily => 'You need to create a family first.';

  @override
  String get memberLimitReached => 'Member limit reached (you + 1).';

  @override
  String get familyMembersTitle => 'Family Members';

  @override
  String get noMembersYet => 'No members yet.';

  @override
  String get unknownMember => 'Unknown';

  @override
  String get shareListTitle => 'Shopping List';

  @override
  String shareListMessage(Object listName) {
    return 'Check out the list $listName on Smart Market List!';
  }
}

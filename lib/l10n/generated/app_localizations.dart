import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get darkModeSystem;

  /// No description provided for @darkModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get darkModeLight;

  /// No description provided for @darkModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkModeDark;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promotion alerts'**
  String get notificationsSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @premiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// No description provided for @shareList.
  ///
  /// In en, this message translates to:
  /// **'Share List'**
  String get shareList;

  /// No description provided for @shareListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync with family'**
  String get shareListSubtitle;

  /// No description provided for @expenseCharts.
  ///
  /// In en, this message translates to:
  /// **'Expense Charts'**
  String get expenseCharts;

  /// No description provided for @expenseChartsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full monthly analysis'**
  String get expenseChartsSubtitle;

  /// No description provided for @exportReports.
  ///
  /// In en, this message translates to:
  /// **'Export Reports'**
  String get exportReports;

  /// No description provided for @exportReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PDF with history'**
  String get exportReportsSubtitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @recipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes for You 👨‍🍳'**
  String get recipesTitle;

  /// No description provided for @recipesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on your ingredients'**
  String get recipesSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search recipe'**
  String get searchHint;

  /// No description provided for @recipesFound.
  ///
  /// In en, this message translates to:
  /// **'Recipes Found'**
  String get recipesFound;

  /// No description provided for @youCanCookNow.
  ///
  /// In en, this message translates to:
  /// **'You Can Cook Now'**
  String get youCanCookNow;

  /// No description provided for @youCanCookNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes with ingredients you already have'**
  String get youCanCookNowSubtitle;

  /// No description provided for @otherRecipes.
  ///
  /// In en, this message translates to:
  /// **'Other Recipes'**
  String get otherRecipes;

  /// No description provided for @otherRecipesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover new recipes and add ingredients to your list'**
  String get otherRecipesSubtitle;

  /// No description provided for @cookTime.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get cookTime;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get navRecipes;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @noLists.
  ///
  /// In en, this message translates to:
  /// **'No lists created'**
  String get noLists;

  /// No description provided for @createList.
  ///
  /// In en, this message translates to:
  /// **'Create List'**
  String get createList;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @clearList.
  ///
  /// In en, this message translates to:
  /// **'Clear List'**
  String get clearList;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @emptyListTitle.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get emptyListTitle;

  /// No description provided for @emptyListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add items to start shopping.'**
  String get emptyListSubtitle;

  /// No description provided for @completedItems.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedItems;

  /// No description provided for @restoreItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Items?'**
  String get restoreItemsTitle;

  /// No description provided for @restoreItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'All completed items will be moved back to the shopping list.'**
  String get restoreItemsMessage;

  /// No description provided for @clearCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed?'**
  String get clearCompletedTitle;

  /// No description provided for @clearCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'All completed items will be permanently removed.'**
  String get clearCompletedMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @shoppingNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping Notes 🧾'**
  String get shoppingNotesTitle;

  /// No description provided for @shoppingNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spending history'**
  String get shoppingNotesSubtitle;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get totalSpent;

  /// No description provided for @savedNotes.
  ///
  /// In en, this message translates to:
  /// **'Saved notes'**
  String get savedNotes;

  /// No description provided for @noSavedNotes.
  ///
  /// In en, this message translates to:
  /// **'No saved notes'**
  String get noSavedNotes;

  /// No description provided for @noSavedNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare prices and save\nby saving your shopping receipts.'**
  String get noSavedNotesSubtitle;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Note?'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note permanently?'**
  String get deleteNoteMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @premiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile 👤'**
  String get profileTitle;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Your personal information'**
  String get personalInfo;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @favoriteRecipesStats.
  ///
  /// In en, this message translates to:
  /// **'Favorite\nRecipes'**
  String get favoriteRecipesStats;

  /// No description provided for @savedNotesStats.
  ///
  /// In en, this message translates to:
  /// **'Saved\nNotes'**
  String get savedNotesStats;

  /// No description provided for @sharingListsStats.
  ///
  /// In en, this message translates to:
  /// **'Sharing\nLists'**
  String get sharingListsStats;

  /// No description provided for @editProfileSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit profile (Coming soon)'**
  String get editProfileSoon;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changePhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @imageError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String imageError(Object error);

  /// No description provided for @clientSince.
  ///
  /// In en, this message translates to:
  /// **'Customer since'**
  String get clientSince;

  /// No description provided for @matchesInList.
  ///
  /// In en, this message translates to:
  /// **'{count} in list'**
  String matchesInList(Object count);

  /// No description provided for @missingIngredients.
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String missingIngredients(Object count);

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @favoriteRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Recipes'**
  String get favoriteRecipesTitle;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite recipes'**
  String get noFavorites;

  /// No description provided for @noFavoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark recipes with ❤️ to see them here'**
  String get noFavoritesSubtitle;

  /// No description provided for @viewNote.
  ///
  /// In en, this message translates to:
  /// **'View note'**
  String get viewNote;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @newNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNoteTitle;

  /// No description provided for @newNoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your purchase'**
  String get newNoteSubtitle;

  /// No description provided for @storeLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeLabel;

  /// No description provided for @storeHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Central Supermarket'**
  String get storeHint;

  /// No description provided for @totalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValueLabel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @notePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Note Photo (optional)'**
  String get notePhotoLabel;

  /// No description provided for @addPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Take photo or choose from gallery'**
  String get addPhotoHint;

  /// No description provided for @saveNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get saveNoteButton;

  /// No description provided for @generalPurchase.
  ///
  /// In en, this message translates to:
  /// **'General Purchase'**
  String get generalPurchase;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @addItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemTitle;

  /// No description provided for @fillFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in the fields'**
  String get fillFields;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Tomato, Bread, Milk...'**
  String get itemNameHint;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions (click to fill)'**
  String get suggestions;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quantityHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 1kg, 2 liters, 500g...'**
  String get quantityHint;

  /// No description provided for @priceOptional.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get priceOptional;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @newCategoryName.
  ///
  /// In en, this message translates to:
  /// **'New category name'**
  String get newCategoryName;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create new category'**
  String get createCategory;

  /// No description provided for @productPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Product Photo (optional)'**
  String get productPhotoOptional;

  /// No description provided for @takePhotoOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Take photo or choose from gallery'**
  String get takePhotoOrGallery;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @currentTotal.
  ///
  /// In en, this message translates to:
  /// **'Current Total'**
  String get currentTotal;

  /// No description provided for @budgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get budgetLimit;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @itemsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} items remaining'**
  String itemsRemaining(Object count);

  /// No description provided for @cat_hortifruti.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get cat_hortifruti;

  /// No description provided for @cat_padaria.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get cat_padaria;

  /// No description provided for @cat_laticinios.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get cat_laticinios;

  /// No description provided for @cat_acougue.
  ///
  /// In en, this message translates to:
  /// **'Meat & Fish'**
  String get cat_acougue;

  /// No description provided for @cat_mercearia.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get cat_mercearia;

  /// No description provided for @cat_bebidas.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get cat_bebidas;

  /// No description provided for @cat_limpeza.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cat_limpeza;

  /// No description provided for @cat_higiene.
  ///
  /// In en, this message translates to:
  /// **'Hygiene'**
  String get cat_higiene;

  /// No description provided for @cat_congelados.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get cat_congelados;

  /// No description provided for @cat_doces.
  ///
  /// In en, this message translates to:
  /// **'Sweets'**
  String get cat_doces;

  /// No description provided for @cat_pet.
  ///
  /// In en, this message translates to:
  /// **'Pet Shop'**
  String get cat_pet;

  /// No description provided for @cat_bebe.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get cat_bebe;

  /// No description provided for @cat_utilidades.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get cat_utilidades;

  /// No description provided for @cat_outros.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get cat_outros;

  /// No description provided for @renameList.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameList;

  /// No description provided for @duplicateList.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateList;

  /// No description provided for @deleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteList;

  /// No description provided for @copySuffix.
  ///
  /// In en, this message translates to:
  /// **' (Copy)'**
  String get copySuffix;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New List'**
  String get newList;

  /// No description provided for @editList.
  ///
  /// In en, this message translates to:
  /// **'Edit List'**
  String get editList;

  /// No description provided for @createPersonalizedList.
  ///
  /// In en, this message translates to:
  /// **'Create a custom list'**
  String get createPersonalizedList;

  /// No description provided for @chooseEmoji.
  ///
  /// In en, this message translates to:
  /// **'Choose an emoji'**
  String get chooseEmoji;

  /// No description provided for @listName.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get listName;

  /// No description provided for @listNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Weekend BBQ'**
  String get listNameHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @createListButton.
  ///
  /// In en, this message translates to:
  /// **'Create List'**
  String get createListButton;

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update details'**
  String get updateDetails;

  /// No description provided for @startPlanning.
  ///
  /// In en, this message translates to:
  /// **'Start planning'**
  String get startPlanning;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @guestMessage.
  ///
  /// In en, this message translates to:
  /// **'Save your data and access from anywhere'**
  String get guestMessage;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Your secure password'**
  String get passwordHint;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get nameHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back! 👋'**
  String get welcomeBack;

  /// No description provided for @welcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We missed you'**
  String get welcomeBackSubtitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account 🚀'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your journey'**
  String get createAccountSubtitle;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @shareEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Share email'**
  String get shareEmailLabel;

  /// No description provided for @sharingWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Sharing with:'**
  String get sharingWithLabel;

  /// No description provided for @shareRealTimeInfo.
  ///
  /// In en, this message translates to:
  /// **'✨ List changes are synchronized in real time'**
  String get shareRealTimeInfo;

  /// No description provided for @shareInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m inviting you to edit my shopping list on Smart Market List. Let\'s save together!'**
  String get shareInviteMessage;

  /// No description provided for @shareLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached (1/1)'**
  String get shareLimitReached;

  /// No description provided for @shareLimitError.
  ///
  /// In en, this message translates to:
  /// **'Only 1 person allowed in the current plan.'**
  String get shareLimitError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Recollecto';

  @override
  String get splashSubtitle => 'Organize and explore your collection';

  @override
  String get home => 'Home';

  @override
  String get explore => 'Explore';

  @override
  String get add => 'Add';

  @override
  String get backup => 'Backup';

  @override
  String get settings => 'Settings';

  @override
  String get categories => 'Categories';

  @override
  String get categoriesSubtitle => 'Create and manage your categories';

  @override
  String get collections => 'Collections';

  @override
  String get collectionsSubtitle => 'Organize your items into collections';

  @override
  String get addItem => 'Add item';

  @override
  String get addItemSubtitle => 'Register a new item in your collection';

  @override
  String get exploreCollection => 'Explore collection';

  @override
  String get exploreCollectionSubtitle => 'Browse your full catalog';

  @override
  String get backupSubtitle => 'Manage local and external backups';

  @override
  String get settingsSubtitle => 'Customize the application';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeSubtitle => 'Manage your collection easily';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Use system language';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get viewLogs => 'View logs';

  @override
  String get viewLogsSubtitle => 'Check app events and errors';

  @override
  String get themeLight => 'Light theme';

  @override
  String get themeLightSubtitle => 'Use a light appearance';

  @override
  String get themeDark => 'Dark theme';

  @override
  String get themeDarkSubtitle => 'Use a dark appearance';

  @override
  String get categoriesAdminSubtitle => 'Create and manage your categories';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'Ex: Figures, Books, Video Games';

  @override
  String get savingCategory => 'Saving...';

  @override
  String get createCategoryButton => 'Create category';

  @override
  String get noCategoriesYet => 'You don\'t have any categories yet.';

  @override
  String get mustEnterCategoryName => 'You must enter a category name.';

  @override
  String get categoryAlreadyExists => 'That category already exists.';

  @override
  String get categoryCreatedSuccessfully => 'Category created successfully.';

  @override
  String get deleteCategoryTitle => 'Delete category';

  @override
  String deleteCategoryConfirmation(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get categoryDeleted => 'Category deleted.';

  @override
  String createdLabel(Object date) {
    return 'Created: $date';
  }

  @override
  String errorLoadingCategories(Object error) {
    return 'Error loading categories: $error';
  }

  @override
  String errorCreatingCategory(Object error) {
    return 'Error creating category: $error';
  }

  @override
  String errorDeletingCategory(Object error) {
    return 'Error deleting category: $error';
  }
}

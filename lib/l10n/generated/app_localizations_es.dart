// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Recollecto';

  @override
  String get splashSubtitle => 'Organiza y explora tu colección';

  @override
  String get home => 'Inicio';

  @override
  String get explore => 'Explorar';

  @override
  String get add => 'Agregar';

  @override
  String get backup => 'Respaldo';

  @override
  String get settings => 'Ajustes';

  @override
  String get categories => 'Categorías';

  @override
  String get categoriesSubtitle => 'Crea y administra tus categorías';

  @override
  String get collections => 'Colecciones';

  @override
  String get collectionsSubtitle => 'Organiza tus ítems en colecciones';

  @override
  String get addItem => 'Agregar ítem';

  @override
  String get addItemSubtitle => 'Registra un nuevo elemento en tu colección';

  @override
  String get exploreCollection => 'Explorar colección';

  @override
  String get exploreCollectionSubtitle => 'Visualiza todo tu catálogo';

  @override
  String get backupSubtitle => 'Gestiona respaldos locales y externos';

  @override
  String get settingsSubtitle => 'Personaliza la aplicación';

  @override
  String get welcomeTitle => 'Bienvenido';

  @override
  String get welcomeSubtitle => 'Gestiona tu colección fácilmente';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Usar idioma del sistema';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get viewLogs => 'Ver registros';

  @override
  String get viewLogsSubtitle => 'Consulta eventos y errores de la app';

  @override
  String get themeLight => 'Tema claro';

  @override
  String get themeLightSubtitle => 'Usa una apariencia clara';

  @override
  String get themeDark => 'Tema oscuro';

  @override
  String get themeDarkSubtitle => 'Usa una apariencia oscura';

  @override
  String get categoriesAdminSubtitle => 'Crea y administra tus categorías';

  @override
  String get categoryNameLabel => 'Nombre de la categoría';

  @override
  String get categoryNameHint => 'Ej: Figuras, Libros, Videojuegos';

  @override
  String get savingCategory => 'Guardando...';

  @override
  String get createCategoryButton => 'Crear categoría';

  @override
  String get noCategoriesYet => 'Todavía no tienes categorías creadas.';

  @override
  String get mustEnterCategoryName =>
      'Debes escribir un nombre para la categoría.';

  @override
  String get categoryAlreadyExists => 'Esa categoría ya existe.';

  @override
  String get categoryCreatedSuccessfully => 'Categoría creada correctamente.';

  @override
  String get deleteCategoryTitle => 'Eliminar categoría';

  @override
  String deleteCategoryConfirmation(Object name) {
    return '¿Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get categoryDeleted => 'Categoría eliminada.';

  @override
  String createdLabel(Object date) {
    return 'Creada: $date';
  }

  @override
  String errorLoadingCategories(Object error) {
    return 'Error cargando categorías: $error';
  }

  @override
  String errorCreatingCategory(Object error) {
    return 'Error al crear la categoría: $error';
  }

  @override
  String errorDeletingCategory(Object error) {
    return 'Error eliminando categoría: $error';
  }
}

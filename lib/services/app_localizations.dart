/// Bilingual (Portuguese / English) localisation helper.
///
/// Uses an [InheritedWidget] so every descendant can call
/// `AppLocalizations.of(context)` to obtain the current locale and
/// all translated UI strings.  Switching language is done by calling
/// [onLocaleChanged], which is wired up to [_CttFinderAppState._setLocale]
/// in `main.dart`.
library;

import 'package:flutter/material.dart';

/// Provides locale-aware UI strings to the widget tree.
///
/// Wrap the [MaterialApp] with this widget and access it via the
/// static [of] method.  All string getters return the Portuguese or
/// English variant depending on the current [locale].
class AppLocalizations extends InheritedWidget {
  /// The currently active locale (e.g. `Locale('pt')`).
  final Locale locale;

  /// Callback to request a language change (triggers a rebuild of the tree).
  final void Function(Locale) onLocaleChanged;

  const AppLocalizations({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  /// Retrieves the nearest [AppLocalizations] ancestor.
  static AppLocalizations of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLocalizations>()!;
  }

  @override
  bool updateShouldNotify(AppLocalizations oldWidget) =>
      locale != oldWidget.locale;

  /// `true` when the current locale is Portuguese.
  bool get isPt => locale.languageCode == 'pt';

  /// Shorthand for the language code (`"pt"` or `"en"`).
  String get t => locale.languageCode;

  // --------------- Welcome screen strings ---------------

  /// Subtitle shown below the app title on the welcome screen.
  String get welcomeSubtitle => isPt
      ? 'Localizador de lojas, marcos e pontos de acesso CTT'
      : 'Locator for CTT stores, mailboxes and access points';
  /// Label for the main call-to-action button on the welcome screen.
  String get welcomeButton => isPt
      ? 'Localizar Lojas e Marcos'
      : 'Find Stores & Mailboxes';

  // --------------- Map screen strings ---------------

  /// Placeholder text for the search bar.
  String get searchHint => isPt
      ? 'Pesquisar estações e marcos...'
      : 'Search stations and mailboxes...';
  String get useFiltersToSearch => isPt
      ? 'Use os filtros para pesquisar'
      : 'Use filters to search';
  String get locations => isPt ? 'locais' : 'locations';
  String get allLocations => isPt ? 'Todos os Locais' : 'All Locations';
  String get errorLoadingLocations => isPt
      ? 'Erro ao carregar localizações'
      : 'Error loading locations';

  // --------------- Filter sheet strings ---------------

  /// Title of the filter bottom-sheet.
  String get filters => isPt ? 'Filtros' : 'Filters';
  String get locationType => isPt ? 'Tipo de Local' : 'Location Type';
  String get storesAndPoints => isPt ? 'Lojas e Pontos CTT' : 'CTT Stores & Points';
  String get mailboxes => isPt ? 'Marcos e Caixas' : 'Mailboxes';
  String get district => isPt ? 'Distrito' : 'District';
  String get municipality => isPt ? 'Concelho' : 'Municipality';
  String get parish => isPt ? 'Freguesia' : 'Parish';
  String get allDistricts => isPt ? 'Todos os distritos' : 'All districts';
  String get allMunicipalities => isPt ? 'Todos os concelhos' : 'All municipalities';
  String get allParishes => isPt ? 'Todas as freguesias' : 'All parishes';
  String get selectDistrictFirst => isPt
      ? 'Selecione um distrito primeiro'
      : 'Select a district first';
  String get selectMunicipalityFirst => isPt
      ? 'Selecione um concelho primeiro'
      : 'Select a municipality first';
  String get clear => isPt ? 'Limpar' : 'Clear';
  String get search => isPt ? 'Pesquisar' : 'Search';

  // --------------- Detail screen strings ---------------

  /// "Address" label.
  String get address => isPt ? 'Morada' : 'Address';
  String get schedule => isPt ? 'Horário' : 'Schedule';
  String get after18h => isPt ? 'Após 18h' : 'After 6 PM';
  String get weekends => isPt ? 'Fim de semana' : 'Weekends';
  String get lastCollection => isPt ? 'Última Recolha' : 'Last Collection';
  String get phone => isPt ? 'Telefone' : 'Phone';
  String get coordinates => isPt ? 'Coordenadas' : 'Coordinates';
  String get directions => isPt ? 'Direções' : 'Directions';
  String get share => isPt ? 'Partilhar' : 'Share';
  String get viewOnCttWebsite => isPt
      ? 'Consultar no site CTT'
      : 'View on CTT website';
  String get services => isPt ? 'Serviços' : 'Services';
  String get copied => isPt ? 'Copiado' : 'Copied';

  // --------------- Location card strings ---------------

  /// Label preceding the last-collection time on the card overlay.
  String get lastCollectionLabel => isPt ? 'Última recolha' : 'Last collection';

  // --------------- Misc ---------------

  /// Label used in the language-toggle button / settings.
  String get language => isPt ? 'Idioma' : 'Language';
}

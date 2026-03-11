// lib/features/prestador/prestador_settings_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/google_places_service.dart';
import 'package:chegaja_v2/core/services/location_data_service.dart';
import 'package:chegaja_v2/core/services/servico_search.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/repositories/servico_repo.dart';
import 'package:chegaja_v2/core/services/user_country_service.dart';
import 'package:chegaja_v2/features/prestador/agenda/prestador_agenda_screen.dart';
import 'package:chegaja_v2/features/common/suporte_screen.dart';
import 'package:chegaja_v2/core/services/locale_service.dart';
import 'package:chegaja_v2/features/common/widgets/place_search_bottom_sheet.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

/// Ecrã de definições do prestador:
/// - serviços que realiza (IDs de `servicos`)
/// - raio de atuação
/// - país / cidade base
///
/// Guarda os dados em `prestadores/{uid}`.
class PrestadorSettingsScreen extends StatefulWidget {
  const PrestadorSettingsScreen({super.key});

  @override
  State<PrestadorSettingsScreen> createState() =>
      _PrestadorSettingsScreenState();
}

class _PrestadorSettingsScreenState extends State<PrestadorSettingsScreen> {
  static const Map<String, String> _stateLabelByCountryCode = {
    'PT': 'district',
    'AO': 'province',
    'MZ': 'province',
    'BR': 'state',
    'US': 'state',
    'CA': 'province',
    'ES': 'province',
    'IT': 'province',
    'FR': 'region',
    'DE': 'state',
    'GB': 'county',
  };

  bool _loading = true;
  bool _saving = false;

  List<Servico> _todosServicos = [];
  final Set<String> _servicosSelecionados = {};
  String _servicoQuery = '';
  ServicoSearchIndex<Servico>? _servicoSearchIndex;
  String _servicoSearchKey = '';

  double _radiusKm = 10;

  final TextEditingController _paisCtrl = TextEditingController();
  final TextEditingController _estadoCtrl = TextEditingController();
  final TextEditingController _cidadeCtrl = TextEditingController();

  final FocusNode _paisFocus = FocusNode();
  final FocusNode _estadoFocus = FocusNode();
  final FocusNode _cidadeFocus = FocusNode();

  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;

  String? _profileCountryCode;
  String? _profileStateCode;

  List<csc.Country> _countries = <csc.Country>[];
  List<csc.State> _statesForCountry = <csc.State>[];
  List<csc.City> _citiesForCountry = <csc.City>[];
  List<csc.City> _citiesForState = <csc.City>[];

  csc.Country? _selectedCountry;
  csc.State? _selectedState;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _paisCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _paisFocus.dispose();
    _estadoFocus.dispose();
    _cidadeFocus.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    try {
      final user =
          AuthService.currentUser; // Assuming _auth is AuthService.instance
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // 1) Buscar servicos ativos do catalogo global (com fallback local)
      final servicosData = await ServicosRepo.buscarServicosAtivosTodos();
      final servicos = [...servicosData]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // 2) Buscar perfil atual do prestador (se existir)
      final docPrestador = await FirebaseFirestore.instance
          .collection('prestadores')
          .doc(user.uid)
          .get();

      String? country;
      String? state;
      String? city;
      String? countryCode;
      String? stateCode;
      double? radius;
      List<dynamic>? servicosIds;

      if (docPrestador.exists) {
        final data = docPrestador.data();
        if (data != null) {
          country = data['country'] as String?;
          state = data['state'] as String?;
          city = data['city'] as String?;
          countryCode =
              (data['countryCode'] ?? data['country_code'])?.toString();
          stateCode = (data['stateCode'] ?? data['provinceCode'])?.toString();
          final r = data['radiusKm'];
          if (r is num) radius = r.toDouble();
          servicosIds = data['servicos'] as List<dynamic>?;
        }
      }

      if (!mounted) return;
      setState(() {
        _todosServicos = servicos;
        _radiusKm = radius ?? _radiusKm;
        _paisCtrl.text = country ?? 'Portugal';
        _estadoCtrl.text = state ?? '';
        _cidadeCtrl.text = city ?? '';
        _profileCountryCode = countryCode;
        _profileStateCode = stateCode;

        _servicosSelecionados.clear();
        if (servicosIds != null) {
          for (final id in servicosIds) {
            if (id is String) {
              _servicosSelecionados.add(id);
            }
          }
        }

        _loading = true;
      });

      await _bootstrapLocation(
        countryName: _paisCtrl.text,
        stateName: _estadoCtrl.text,
        countryCode: _profileCountryCode,
        stateCode: _profileStateCode,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.providerSettingsLoadError(e.toString())),
        ),
      );
    }
  }

  String _stateLabelForCountry(csc.Country? country) {
    final l10n = AppLocalizations.of(context)!;
    final labelKey = country == null
        ? null
        : _stateLabelByCountryCode[country.isoCode.toUpperCase()];
    switch (labelKey) {
      case 'district':
        return l10n.stateLabelDistrict;
      case 'province':
        return l10n.stateLabelProvince;
      case 'state':
        return l10n.stateLabelState;
      case 'region':
        return l10n.stateLabelRegion;
      case 'county':
        return l10n.stateLabelCounty;
      default:
        return l10n.stateLabelRegionOrState;
    }
  }

  csc.Country? _findCountryByIso(String? code) {
    final iso = code?.trim().toUpperCase();
    if (iso == null || iso.isEmpty) return null;
    for (final c in _countries) {
      if (c.isoCode.toUpperCase() == iso) return c;
    }
    return null;
  }

  csc.State? _findStateByIso(String? code) {
    final iso = code?.trim().toUpperCase();
    if (iso == null || iso.isEmpty) return null;
    for (final s in _statesForCountry) {
      if (s.isoCode.toUpperCase() == iso) return s;
    }
    return null;
  }

  Future<void> _loadCountries() async {
    if (_countries.isNotEmpty || _loadingCountries) return;
    setState(() => _loadingCountries = true);
    try {
      final list = await LocationDataService.instance
          .getCountries()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => _countries = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _countries = <csc.Country>[]);
    } finally {
      if (mounted) {
        setState(() => _loadingCountries = false);
      }
    }
  }

  Future<void> _loadStatesForCountry(String countryCode) async {
    setState(() => _loadingStates = true);
    try {
      final list = await LocationDataService.instance
          .getStatesForCountryCode(countryCode)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _statesForCountry = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statesForCountry = <csc.State>[]);
    } finally {
      if (mounted) {
        setState(() => _loadingStates = false);
      }
    }
  }

  Future<void> _loadCitiesForState(String countryCode, String stateCode) async {
    setState(() => _loadingCities = true);
    try {
      final list = await LocationDataService.instance
          .getCitiesForState(countryCode, stateCode)
          .timeout(const Duration(seconds: 60));
      if (!mounted) return;
      setState(() => _citiesForState = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _citiesForState = <csc.City>[]);
    } finally {
      if (mounted) {
        setState(() => _loadingCities = false);
      }
    }
  }

  Future<void> _loadCitiesForCountry(String countryCode) async {
    setState(() => _loadingCities = true);
    try {
      final list = await LocationDataService.instance
          .getCitiesForCountryCode(countryCode)
          .timeout(const Duration(seconds: 60));
      if (!mounted) return;
      setState(() => _citiesForCountry = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _citiesForCountry = <csc.City>[]);
    } finally {
      if (mounted) {
        setState(() => _loadingCities = false);
      }
    }
  }

  Future<void> _bootstrapLocation({
    required String? countryName,
    required String? stateName,
    required String? countryCode,
    required String? stateCode,
  }) async {
    await _loadCountries();
    if (!mounted) return;

    var country = _findCountryByIso(countryCode);
    country ??= await LocationDataService.instance.findCountryByName(
      countryName ?? '',
    );

    if (country == null) return;
    final selectedCountry = country;

    setState(() {
      _selectedCountry = selectedCountry;
      _profileCountryCode = selectedCountry.isoCode;
      _paisCtrl.text = selectedCountry.name;
    });

    await _loadStatesForCountry(selectedCountry.isoCode);

    if (_statesForCountry.isNotEmpty) {
      var state = _findStateByIso(stateCode);
      state ??= await LocationDataService.instance.findStateByName(
        country.isoCode,
        stateName ?? '',
      );
      if (state != null) {
        final selectedState = state;
        setState(() {
          _selectedState = selectedState;
          _profileStateCode = selectedState.isoCode;
          _estadoCtrl.text = selectedState.name;
        });
        unawaited(
          _loadCitiesForState(
            selectedState.countryCode,
            selectedState.isoCode,
          ),
        );
        return;
      }
    }

    unawaited(_loadCitiesForCountry(selectedCountry.isoCode));
  }

  Future<void> _onCountrySelected(csc.Country country) async {
    setState(() {
      _selectedCountry = country;
      _profileCountryCode = country.isoCode;
      _paisCtrl.text = country.name;
      _statesForCountry = <csc.State>[];
      _citiesForCountry = <csc.City>[];
      _citiesForState = <csc.City>[];
      _selectedState = null;
      _profileStateCode = null;
      _estadoCtrl.clear();
      _cidadeCtrl.clear();
    });

    await _loadStatesForCountry(country.isoCode);

    if (_statesForCountry.isEmpty) {
      await _loadCitiesForCountry(country.isoCode);
    }
  }

  Future<void> _onStateSelected(csc.State state) async {
    setState(() {
      _selectedState = state;
      _profileStateCode = state.isoCode;
      _estadoCtrl.text = state.name;
      _cidadeCtrl.clear();
    });

    await _loadCitiesForState(state.countryCode, state.isoCode);
  }

  void _ensureServicoSearchIndex(Locale locale) {
    final key = _todosServicos.isEmpty
        ? 'empty'
        : '${locale.languageCode}:${_todosServicos.length}:${_todosServicos.first.id}:${_todosServicos.last.id}';
    if (_servicoSearchIndex != null && _servicoSearchKey == key) return;
    _servicoSearchKey = key;
    _servicoSearchIndex = ServicoSearchIndex<Servico>(
      items: _todosServicos,
      id: (s) => s.id,
      name: (s) => s.nameForLang(locale.languageCode),
      keywords: (s) => s.keywords,
      mode: (s) => s.mode,
    );
  }

  List<Servico> _servicosSelecionadosOrdenados(Locale locale) {
    final selected = _todosServicos
        .where((s) => _servicosSelecionados.contains(s.id))
        .toList();
    selected.sort(
      (a, b) => a
          .nameForLang(locale.languageCode)
          .compareTo(b.nameForLang(locale.languageCode)),
    );
    return selected;
  }

  List<Servico> _filterServicos(Locale locale) {
    final query = _servicoQuery.trim();
    if (query.isEmpty) {
      return _servicosSelecionadosOrdenados(locale);
    }
    _ensureServicoSearchIndex(locale);
    return _servicoSearchIndex?.search(query, limit: 80) ?? const [];
  }

  String _normalizeServicoMode(String? mode) {
    final raw = (mode ?? '').toUpperCase().trim();
    if (raw == 'POR_PROPOSTA' || raw == 'ORCAMENTO' || raw == 'POR_ORCAMENTO') {
      return 'ORCAMENTO';
    }
    if (raw == 'AGENDADO') return 'AGENDADO';
    if (raw == 'IMEDIATO') return 'IMEDIATO';
    return 'IMEDIATO';
  }

  List<Widget> _buildServicoSections(List<Servico> servicos, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    final grouped = <String, List<Servico>>{
      'ORCAMENTO': <Servico>[],
      'AGENDADO': <Servico>[],
      'IMEDIATO': <Servico>[],
    };

    for (final servico in servicos) {
      final mode = _normalizeServicoMode(servico.mode);
      grouped[mode]!.add(servico);
    }

    Widget buildTile(Servico s) {
      final displayName = s.nameForLang(locale.languageCode);
      final label = displayName.isNotEmpty ? displayName : l10n.serviceUnnamed;
      return CheckboxListTile(
        value: _servicosSelecionados.contains(s.id),
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _servicosSelecionados.add(s.id);
            } else {
              _servicosSelecionados.remove(s.id);
            }
          });
        },
        title: Text(label),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    void addSection(
      List<Widget> out,
      String mode,
      String label,
    ) {
      final items = grouped[mode] ?? const <Servico>[];
      if (items.isEmpty) return;
      out.add(
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      out.add(const SizedBox(height: 6));
      out.addAll(items.map(buildTile));
      out.add(const SizedBox(height: 12));
    }

    final sections = <Widget>[];
    addSection(sections, 'ORCAMENTO', l10n.serviceModeQuote);
    addSection(sections, 'AGENDADO', l10n.serviceModeScheduled);
    addSection(sections, 'IMEDIATO', l10n.serviceModeImmediate);
    if (sections.isNotEmpty) {
      sections.removeLast();
    }
    return sections;
  }

  Future<void> _guardar() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;

    if (_servicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.providerServicesSelectAtLeastOne),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final ref =
          FirebaseFirestore.instance.collection('prestadores').doc(user.uid);

      final selecionados = _todosServicos
          .where((s) => _servicosSelecionados.contains(s.id))
          .toList();
      final ids = selecionados.map((s) => s.id).toList();
      final nomes = selecionados.map((s) => s.name).toList();

      await ref.set(
        {
          'userId': user.uid,
          'servicos': ids,
          // estes nomes são usados para bater com pedido.categoria
          'servicosNomes': nomes,
          'radiusKm': _radiusKm,
          'country': _paisCtrl.text.trim(),
          'countryCode': _selectedCountry?.isoCode,
          'state': _estadoCtrl.text.trim(),
          'stateCode': _selectedState?.isoCode,
          'city': _cidadeCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final countryCode = _selectedCountry?.isoCode;
      if (countryCode != null && countryCode.isNotEmpty) {
        await UserCountryService.instance.setManualCountry(countryCode);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.serviceAreaSaved),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.providerSettingsSaveError(e.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<T?> _showSearchBottomSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    String? hintText,
    int maxResults = 200,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveHint = hintText ?? l10n.searchHint;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final searchCtrl = TextEditingController();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final q = LocationDataService.normalize(searchCtrl.text);
                final filtered = <T>[];
                if (q.isEmpty) {
                  filtered.addAll(items.take(80));
                } else {
                  for (final it in items) {
                    final name = LocationDataService.normalize(label(it));
                    if (name.contains(q)) {
                      filtered.add(it);
                      if (filtered.length >= maxResults) break;
                    }
                  }
                }

                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: effectiveHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final it = filtered[i];
                              return ListTile(
                                title: Text(label(it)),
                                onTap: () => Navigator.of(ctx).pop(it),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _autocompleteOptionsView<T extends Object>(
    BuildContext context,
    AutocompleteOnSelected<T> onSelected,
    Iterable<T> options,
    String Function(T) label,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 240,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                title: Text(label(option)),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _countryField() {
    final l10n = AppLocalizations.of(context)!;
    return RawAutocomplete<csc.Country>(
      textEditingController: _paisCtrl,
      focusNode: _paisFocus,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (TextEditingValue value) {
        if (_countries.isEmpty) return const Iterable<csc.Country>.empty();
        final q = LocationDataService.normalize(value.text);
        if (q.isEmpty) return _countries.take(20);
        return _countries.where((c) {
          return LocationDataService.normalize(c.name).contains(q);
        }).take(20);
      },
      onSelected: (c) => _onCountrySelected(c),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: l10n.countryLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: _loadingCountries
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: l10n.openCountriesListTooltip,
                    onPressed: () async {
                      if (_countries.isEmpty) return;
                      final selected =
                          await _showSearchBottomSheet<csc.Country>(
                        title: l10n.selectCountryTitle,
                        hintText: l10n.searchCountryHint,
                        items: _countries,
                        label: (c) => c.name,
                        maxResults: 200,
                      );
                      if (selected != null) {
                        await _onCountrySelected(selected);
                      }
                    },
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
          ),
          onChanged: (txt) {
            if (_selectedCountry == null) return;
            final same = LocationDataService.normalize(txt) ==
                LocationDataService.normalize(_selectedCountry!.name);
            if (!same) {
              setState(() {
                _selectedCountry = null;
                _profileCountryCode = null;
                _statesForCountry = <csc.State>[];
                _citiesForCountry = <csc.City>[];
                _citiesForState = <csc.City>[];
                _selectedState = null;
                _profileStateCode = null;
                _estadoCtrl.clear();
                _cidadeCtrl.clear();
              });
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _autocompleteOptionsView<csc.Country>(
          context,
          onSelected,
          options,
          (c) => c.name,
        );
      },
    );
  }

  Widget _stateField(String label) {
    final l10n = AppLocalizations.of(context)!;
    return RawAutocomplete<csc.State>(
      textEditingController: _estadoCtrl,
      focusNode: _estadoFocus,
      displayStringForOption: (s) => s.name,
      optionsBuilder: (TextEditingValue value) {
        if (_statesForCountry.isEmpty) return const Iterable<csc.State>.empty();
        final q = LocationDataService.normalize(value.text);
        if (q.isEmpty) return _statesForCountry.take(20);
        return _statesForCountry
            .where((s) => LocationDataService.normalize(s.name).contains(q))
            .take(20);
      },
      onSelected: (s) => _onStateSelected(s),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: _loadingStates
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: l10n.openListTooltip,
                    onPressed: () async {
                      final selected = await PlaceSearchBottomSheet.show(
                        context: context,
                        title: l10n.selectFieldTitle(label),
                        hintText: l10n.searchGenericHint,
                        localItems:
                            _statesForCountry.map((s) => s.name).toList(),
                        type: PlaceSearchType.region,
                        countryCode: _selectedCountry?.isoCode ??
                            UserCountryService.instance.countryCode,
                        maxLocal: 200,
                      );
                      if (selected == null) return;

                      csc.State? localMatch;
                      final normalized =
                          LocationDataService.normalize(selected);
                      for (final s in _statesForCountry) {
                        if (LocationDataService.normalize(s.name) ==
                            normalized) {
                          localMatch = s;
                          break;
                        }
                      }

                      if (localMatch != null) {
                        await _onStateSelected(localMatch);
                      } else {
                        setState(() {
                          _selectedState = null;
                          _profileStateCode = null;
                          _estadoCtrl.text = selected;
                          _citiesForState = <csc.City>[];
                          _cidadeCtrl.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
          ),
          onChanged: (txt) {
            if (_selectedState == null) return;
            final same = LocationDataService.normalize(txt) ==
                LocationDataService.normalize(_selectedState!.name);
            if (!same) {
              setState(() {
                _selectedState = null;
                _profileStateCode = null;
                _citiesForState = <csc.City>[];
                _cidadeCtrl.clear();
              });
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _autocompleteOptionsView<csc.State>(
          context,
          onSelected,
          options,
          (s) => s.name,
        );
      },
    );
  }

  Widget _cityField({
    required List<csc.City> cities,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return RawAutocomplete<csc.City>(
      textEditingController: _cidadeCtrl,
      focusNode: _cidadeFocus,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (TextEditingValue value) {
        if (cities.isEmpty) return const Iterable<csc.City>.empty();
        final q = LocationDataService.normalize(value.text);
        if (q.isEmpty) return cities.take(20);
        return cities.where((c) {
          return LocationDataService.normalize(c.name).contains(q);
        }).take(20);
      },
      onSelected: (c) => setState(() => _cidadeCtrl.text = c.name),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: l10n.cityLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: _loadingCities
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: l10n.openListTooltip,
                    onPressed: () async {
                      final selected = await PlaceSearchBottomSheet.show(
                        context: context,
                        title: l10n.selectCityTitle,
                        hintText: l10n.searchGenericHint,
                        localItems: cities.map((c) => c.name).toList(),
                        type: PlaceSearchType.city,
                        countryCode: _selectedCountry?.isoCode ??
                            UserCountryService.instance.countryCode,
                        maxLocal: 200,
                      );
                      if (selected != null) {
                        setState(() => _cidadeCtrl.text = selected);
                      }
                    },
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _autocompleteOptionsView<csc.City>(
          context,
          onSelected,
          options,
          (c) => c.name,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final hasStates = _statesForCountry.isNotEmpty;
    final locale = Localizations.localeOf(context);
    final stateLabel = _stateLabelForCountry(_selectedCountry);
    final cities = hasStates ? _citiesForState : _citiesForCountry;
    final hasQuery = _servicoQuery.trim().isNotEmpty;
    final servicosVisiveis = _filterServicos(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serviceAreaTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          l10n.serviceAreaHeading,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.serviceAreaSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Localização base
                        Text(
                          l10n.serviceAreaBaseLocation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _countryField(),
                        const SizedBox(height: 8),
                        hasStates
                            ? _stateField(stateLabel)
                            : _field(stateLabel, _estadoCtrl),
                        const SizedBox(height: 8),
                        _cityField(cities: cities),
                        const SizedBox(height: 16),

                        // Raio
                        Text(
                          l10n.serviceAreaRadius,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _radiusKm,
                                min: 5,
                                max: 50,
                                divisions: 9, // 5,10,...,50
                                label: '${_radiusKm.round()} km',
                                onChanged: (v) {
                                  setState(() {
                                    _radiusKm = v;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_radiusKm.round()} km',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 16),

                        // Agenda
                        Text(
                          l10n.availabilityTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // --- Cartão de Agenda (Existente) ---
                        // --- Idioma ---
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(
                              Icons.language,
                              color: Colors.purple,
                              size: 32,
                            ),
                            title: Text(l10n.languageTitle),
                            subtitle: Text(
                              l10n.languageModeLabel(
                                LocaleService.instance.locale.languageCode
                                    .toUpperCase(),
                                LocaleService.instance.isManualOverride
                                    ? l10n.languageModeManual
                                    : l10n.languageModeAuto,
                              ),
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              _showLanguagePicker(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Cartão de Agenda (Existente) ---
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(
                              Icons.calendar_month,
                              color: Colors.blueAccent,
                              size: 32,
                            ),
                            title: Text(l10n.myScheduleTitle),
                            subtitle: Text(l10n.myScheduleSubtitle),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PrestadorAgendaScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Serviços
                        Text(
                          l10n.servicesYouProvideTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_todosServicos.isEmpty)
                          Text(
                            l10n.servicesCatalogEmpty,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          )
                        else
                          Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: l10n.searchServicesHint,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: hasQuery
                                      ? IconButton(
                                          onPressed: () {
                                            setState(() => _servicoQuery = '');
                                          },
                                          icon: const Icon(Icons.clear),
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() => _servicoQuery = value);
                                },
                              ),
                              const SizedBox(height: 8),
                              if (!hasQuery && servicosVisiveis.isEmpty)
                                Text(
                                  l10n.servicesSearchPrompt,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                )
                              else if (servicosVisiveis.isEmpty)
                                Text(
                                  l10n.servicesSearchNoResults,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                )
                              else ...[
                                if (!hasQuery)
                                  Text(
                                    l10n.servicesSelectedTitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildServicoSections(
                                    servicosVisiveis,
                                    locale,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 24),

                        // --- Cartão de Suporte ---
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(
                              Icons.help_outline,
                              color: Colors.blueGrey,
                              size: 32,
                            ),
                            title: Text(l10n.supportTitle),
                            subtitle: Text(l10n.supportSubtitle),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SuporteScreen(
                                    userType: 'prestador',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            l10n.serviceAreaInfoNote,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _guardar,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(l10n.saveChanges),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  } // This closing brace was added based on the instruction's context.

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const LanguageSelectorWidget(),
    );
  }
} // This closing brace was added based on the instruction's context.

class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const locales = AppLocalizations.supportedLocales;
    const namesByCode = {
      'pt': 'Português',
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'ru': 'Русский',
      'zh': '中文',
    };

    return AnimatedBuilder(
      animation: LocaleService.instance,
      builder: (context, _) {
        final current = LocaleService.instance.locale;
        final isAuto = !LocaleService.instance.isManualOverride;

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(l10n.languageAutoSystem),
                trailing: isAuto ? const Icon(Icons.check) : null,
                onTap: () async {
                  await LocaleService.instance.clearLocale();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const Divider(height: 1),
              for (final locale in locales)
                ListTile(
                  title: Text(
                    namesByCode[locale.languageCode] ??
                        locale.languageCode.toUpperCase(),
                  ),
                  trailing: current.languageCode == locale.languageCode
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    await LocaleService.instance.setLocale(locale);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

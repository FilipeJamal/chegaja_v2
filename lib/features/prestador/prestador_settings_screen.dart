// lib/features/prestador/prestador_settings_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/location_data_service.dart';
import 'package:chegaja_v2/core/services/servico_search.dart';
import 'package:chegaja_v2/core/repositories/servico_repo.dart';

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
    'PT': 'Distrito',
    'AO': 'Provincia',
    'MZ': 'Provincia',
    'BR': 'Estado',
    'US': 'Estado',
    'CA': 'Provincia',
    'ES': 'Provincia',
    'IT': 'Provincia',
    'FR': 'Regiao',
    'DE': 'Estado',
    'GB': 'Condado',
  };

  bool _loading = true;
  bool _saving = false;

  List<_ServicoItem> _todosServicos = [];
  final Set<String> _servicosSelecionados = {};
  String _servicoQuery = '';
  ServicoSearchIndex<_ServicoItem>? _servicoSearchIndex;
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
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // 1) Buscar servicos ativos do catalogo global (com fallback local)
      final servicosData = await ServicosRepo.buscarServicosAtivosTodos();
      final servicos = servicosData
          .map(
            (s) => _ServicoItem(
              id: s.id,
              name: s.name.isNotEmpty ? s.name : 'Sem nome',
              mode: s.mode,
              keywords: s.keywords,
            ),
          )
          .toList();
      servicos.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

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
          countryCode = (data['countryCode'] ?? data['country_code'])?.toString();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar definições: $e'),
        ),
      );
    }
  }

  String _stateLabelForCountry(csc.Country? country) {
    if (country == null) return 'Regiao/Estado';
    return _stateLabelByCountryCode[country.isoCode.toUpperCase()] ??
        'Regiao/Estado';
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
      final list = await LocationDataService.instance.getCountries();
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
      final list = await LocationDataService.instance.getStatesForCountryCode(
        countryCode,
      );
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
      final list = await LocationDataService.instance.getCitiesForState(
        countryCode,
        stateCode,
      );
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
      final list =
          await LocationDataService.instance.getCitiesForCountryCode(countryCode);
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
        await _loadCitiesForState(
          selectedState.countryCode,
          selectedState.isoCode,
        );
        return;
      }
    }

    await _loadCitiesForCountry(selectedCountry.isoCode);
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

  void _ensureServicoSearchIndex() {
    final key = _todosServicos.isEmpty
        ? 'empty'
        : '${_todosServicos.length}:${_todosServicos.first.id}:${_todosServicos.last.id}';
    if (_servicoSearchIndex != null && _servicoSearchKey == key) return;
    _servicoSearchKey = key;
    _servicoSearchIndex = ServicoSearchIndex<_ServicoItem>(
      items: _todosServicos,
      id: (s) => s.id,
      name: (s) => s.name,
      keywords: (s) => s.keywords,
      mode: (s) => s.mode ?? '',
    );
  }

  List<_ServicoItem> _servicosSelecionadosOrdenados() {
    final selected = _todosServicos
        .where((s) => _servicosSelecionados.contains(s.id))
        .toList();
    selected.sort((a, b) => a.name.compareTo(b.name));
    return selected;
  }

  List<_ServicoItem> _filterServicos() {
    final query = _servicoQuery.trim();
    if (query.isEmpty) {
      return _servicosSelecionadosOrdenados();
    }
    _ensureServicoSearchIndex();
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

  List<Widget> _buildServicoSections(List<_ServicoItem> servicos) {
    final grouped = <String, List<_ServicoItem>>{
      'ORCAMENTO': <_ServicoItem>[],
      'AGENDADO': <_ServicoItem>[],
      'IMEDIATO': <_ServicoItem>[],
    };

    for (final servico in servicos) {
      final mode = _normalizeServicoMode(servico.mode);
      grouped[mode]!.add(servico);
    }

    Widget buildTile(_ServicoItem s) {
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
        title: Text(s.name),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    void addSection(
      List<Widget> out,
      String mode,
      String label,
    ) {
      final items = grouped[mode] ?? const <_ServicoItem>[];
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
    addSection(sections, 'ORCAMENTO', 'Orcamento');
    addSection(sections, 'AGENDADO', 'Agendado');
    addSection(sections, 'IMEDIATO', 'Imediato');
    if (sections.isNotEmpty) {
      sections.removeLast();
    }
    return sections;
  }

  Future<void> _guardar() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (_servicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escolhe pelo menos um serviço que realizas.',
          ),
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Área de atuação guardada com sucesso.'),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao guardar definições: $e'),
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
    String hintText = 'Pesquisar...',
    int maxResults = 200,
  }) {
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: hintText,
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
            labelText: 'Pais',
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
                    tooltip: 'Ver lista de paises',
                    onPressed: () async {
                      if (_countries.isEmpty) return;
                      final selected = await _showSearchBottomSheet<csc.Country>(
                        title: 'Escolher pais',
                        hintText: 'Escreve para pesquisar paises',
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
                    tooltip: 'Ver lista',
                    onPressed: () async {
                      if (_statesForCountry.isEmpty) return;
                      final selected = await _showSearchBottomSheet<csc.State>(
                        title: 'Escolher $label',
                        hintText: 'Escreve para pesquisar',
                        items: _statesForCountry,
                        label: (s) => s.name,
                        maxResults: 200,
                      );
                      if (selected != null) {
                        await _onStateSelected(selected);
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
            labelText: 'Cidade',
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
                    tooltip: 'Ver lista',
                    onPressed: cities.isEmpty
                        ? null
                        : () async {
                            final selected =
                                await _showSearchBottomSheet<csc.City>(
                              title: 'Escolher cidade',
                              hintText: 'Escreve para pesquisar',
                              items: cities,
                              label: (c) => c.name,
                              maxResults: 200,
                            );
                            if (selected != null) {
                              setState(() => _cidadeCtrl.text = selected.name);
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
    final primary = Theme.of(context).colorScheme.primary;
    final hasStates = _statesForCountry.isNotEmpty;
    final stateLabel = _stateLabelForCountry(_selectedCountry);
    final cities = hasStates ? _citiesForState : _citiesForCountry;
    final hasQuery = _servicoQuery.trim().isNotEmpty;
    final servicosVisiveis = _filterServicos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área de atuação'),
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
                        const Text(
                          'Onde queres receber pedidos?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Define os serviços que fazes e o raio máximo em torno da tua cidade base.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Localização base
                        const Text(
                          'Localização base',
                          style: TextStyle(
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
                        const Text(
                          'Raio de atuação',
                          style: TextStyle(
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

                        // Serviços
                        const Text(
                          'Serviços que realizas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_todosServicos.isEmpty)
                          const Text(
                            'Ainda não há serviços configurados no catálogo.',
                            style: TextStyle(
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
                                  hintText: 'Pesquisar servicos',
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
                                const Text(
                                  'Escreve para pesquisar e adicionar servicos.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                )
                              else if (servicosVisiveis.isEmpty)
                                const Text(
                                  'Nenhum servico encontrado.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                )
                              else ...[
                                if (!hasQuery)
                                  const Text(
                                    'Servicos selecionados',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildServicoSections(servicosVisiveis),
                                ),
                              ],
                            ],
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
                          child: const Text(
                            'No futuro vamos usar estas definições para '
                            'filtrar pedidos por proximidade e tipo de serviço. '
                            'Por agora, isto ajuda-nos a preparar o motor de matching. 😊',
                            style: TextStyle(
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
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Guardar alterações'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ServicoItem {
  final String id;
  final String name;
  final String? mode;
  final List<String> keywords;

  _ServicoItem({
    required this.id,
    required this.name,
    this.mode,
    this.keywords = const [],
  });
}

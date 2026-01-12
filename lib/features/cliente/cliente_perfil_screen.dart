// lib/features/cliente/cliente_perfil_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import 'package:chegaja_v2/core/services/location_data_service.dart';
import 'package:chegaja_v2/features/common/widgets/media_viewer_screen.dart';

class ClientePerfilScreen extends StatefulWidget {
  const ClientePerfilScreen({super.key});

  @override
  State<ClientePerfilScreen> createState() => _ClientePerfilScreenState();
}

class _ClientePerfilScreenState extends State<ClientePerfilScreen> {
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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _paisCtrl = TextEditingController();
  final TextEditingController _estadoCtrl = TextEditingController();
  final TextEditingController _cidadeCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  final FocusNode _paisFocus = FocusNode();
  final FocusNode _estadoFocus = FocusNode();
  final FocusNode _cidadeFocus = FocusNode();

  bool _loading = true;
  bool _saving = false;
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;

  String? _photoUrl;
  String? _profileCountryCode;
  String? _profileStateCode;
  String? _profilePhoneIso;
  String _dialCode = '';

  List<csc.Country> _countries = <csc.Country>[];
  List<csc.State> _statesForCountry = <csc.State>[];
  List<csc.City> _citiesForCountry = <csc.City>[];
  List<csc.City> _citiesForState = <csc.City>[];

  csc.Country? _selectedCountry;
  csc.State? _selectedState;

  String? get _uidOrNull => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _docOrNull {
    final uid = _uidOrNull;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadCountries();
    _phoneCtrl.addListener(() {
      _onPhoneChanged(_phoneCtrl.text);
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _bioCtrl.dispose();
    _paisCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _phoneCtrl.dispose();
    _paisFocus.dispose();
    _estadoFocus.dispose();
    _cidadeFocus.dispose();
    super.dispose();
  }

  String _stateLabelForCountry(csc.Country? country) {
    if (country == null) return 'Regiao/Estado';
    return _stateLabelByCountryCode[country.isoCode.toUpperCase()] ?? 'Regiao/Estado';
  }

  IsoCode? _isoFromCountryCode(String? isoCode) {
    if (isoCode == null) return null;
    try {
      return IsoCode.values.byName(isoCode.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  String _dialCodeForIso(IsoCode? isoCode) {
    if (isoCode == null) return '';
    try {
      final number = PhoneNumber(isoCode: isoCode, nsn: '0');
      return '+${number.countryCode}';
    } catch (_) {
      return '';
    }
  }

  void _updateDialCodeFromCountry(csc.Country? country) {
    final iso = _isoFromCountryCode(country?.isoCode);
    final dial = _dialCodeForIso(iso);
    if (dial.isEmpty) return;
    setState(() => _dialCode = dial);
  }

  void _onPhoneChanged(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return;
    if (!raw.startsWith('+')) return;

    try {
      final parsed = PhoneNumber.parse(raw);
      final iso = parsed.isoCode.name;
      if (_selectedCountry?.isoCode != iso) {
        _setCountryByIsoCode(iso);
      }
      if (_dialCode != '+${parsed.countryCode}') {
        setState(() => _dialCode = '+${parsed.countryCode}');
      }
    } catch (_) {
      // ignore invalid numbers
    }
  }

  Future<void> _load() async {
    final doc = _docOrNull;
    if (doc == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final snap = await doc.get();
      final data = snap.data() ?? <String, dynamic>{};

      _nomeCtrl.text = (data['nome'] ?? data['displayName'] ?? '').toString();
      _bioCtrl.text = (data['bio'] ?? '').toString();
      _paisCtrl.text = (data['country'] ?? '').toString();
      _estadoCtrl.text = (data['state'] ?? data['province'] ?? '').toString();
      _cidadeCtrl.text = (data['city'] ?? '').toString();
      _photoUrl = (data['photoUrl'] ?? data['fotoUrl'])?.toString();

      _profileCountryCode = (data['countryCode'] ?? data['country_code'])?.toString();
      _profileStateCode = (data['stateCode'] ?? data['provinceCode'])?.toString();
      _profilePhoneIso = (data['phoneIsoCode'] ?? data['phoneCountryCode'])?.toString();

      final phone = (data['phoneE164'] ?? data['phoneNumber'] ?? data['phone'] ?? '')
          .toString()
          .trim();
      if (phone.isNotEmpty) {
        _phoneCtrl.text = phone;
        if ((_profilePhoneIso == null || _profilePhoneIso!.isEmpty) && phone.startsWith('+')) {
          try {
            final parsed = PhoneNumber.parse(phone);
            _profilePhoneIso = parsed.isoCode.name;
          } catch (_) {
            // ignore parse failures
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCountries() async {
    if (_loadingCountries) return;
    setState(() => _loadingCountries = true);

    try {
      final list = await LocationDataService.instance.getCountries();
      if (!mounted) return;
      setState(() => _countries = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _countries = <csc.Country>[]);
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }

    await _syncSelectedCountryFromProfileOrText();
  }

  Future<void> _syncSelectedCountryFromProfileOrText() async {
    if (_countries.isEmpty) return;

    csc.Country? found;
    final code = _profileCountryCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      for (final c in _countries) {
        if (c.isoCode.toUpperCase() == code) {
          found = c;
          break;
        }
      }
    }
    if (found == null && _profilePhoneIso != null && _profilePhoneIso!.isNotEmpty) {
      final iso = _profilePhoneIso!.toUpperCase();
      for (final c in _countries) {
        if (c.isoCode.toUpperCase() == iso) {
          found = c;
          break;
        }
      }
    }
    found ??= await LocationDataService.instance.findCountryByName(_paisCtrl.text);

    if (found == null) return;
    await _onCountrySelected(found);
  }

  Future<void> _setCountryByIsoCode(String isoCode) async {
    if (_countries.isEmpty) return;
    final iso = isoCode.toUpperCase();
    final match = _countries.where((c) => c.isoCode.toUpperCase() == iso).toList();
    if (match.isEmpty) return;
    if (_selectedCountry?.isoCode == match.first.isoCode) return;
    await _onCountrySelected(match.first);
  }

  Future<void> _onCountrySelected(csc.Country country) async {
    setState(() {
      _selectedCountry = country;
      _paisCtrl.text = country.name;
      _profileCountryCode = country.isoCode;
      _statesForCountry = <csc.State>[];
      _citiesForCountry = <csc.City>[];
      _citiesForState = <csc.City>[];
      _selectedState = null;
      _estadoCtrl.clear();
      _cidadeCtrl.clear();
    });

    _updateDialCodeFromCountry(country);
    await _loadStatesForCountry(country.isoCode);
  }

  Future<void> _loadStatesForCountry(String countryCode) async {
    if (_loadingStates) return;
    setState(() => _loadingStates = true);

    try {
      final list = await LocationDataService.instance.getStatesForCountryCode(countryCode);
      if (!mounted) return;
      setState(() => _statesForCountry = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statesForCountry = <csc.State>[]);
    } finally {
      if (mounted) setState(() => _loadingStates = false);
    }

    if (_statesForCountry.isEmpty) {
      await _loadCitiesForCountry(countryCode);
      return;
    }
    await _syncSelectedStateFromProfileOrText();
  }

  Future<void> _syncSelectedStateFromProfileOrText() async {
    final country = _selectedCountry;
    if (country == null || _statesForCountry.isEmpty) return;

    csc.State? found;
    final code = _profileStateCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      for (final s in _statesForCountry) {
        if (s.isoCode.toUpperCase() == code) {
          found = s;
          break;
        }
      }
    }
    found ??= await LocationDataService.instance.findStateByName(
      country.isoCode,
      _estadoCtrl.text,
    );

    if (found == null) return;
    await _onStateSelected(found);
  }

  Future<void> _onStateSelected(csc.State state) async {
    setState(() {
      _selectedState = state;
      _estadoCtrl.text = state.name;
      _profileStateCode = state.isoCode;
      _citiesForState = <csc.City>[];
      _cidadeCtrl.clear();
    });

    await _loadCitiesForState(state.countryCode, state.isoCode);
  }

  Future<void> _loadCitiesForState(String countryCode, String stateCode) async {
    if (_loadingCities) return;
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
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _loadCitiesForCountry(String countryCode) async {
    if (_loadingCities) return;
    setState(() => _loadingCities = true);
    try {
      final list = await LocationDataService.instance.getCitiesForCountryCode(countryCode);
      if (!mounted) return;
      setState(() => _citiesForCountry = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _citiesForCountry = <csc.City>[]);
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _save() async {
    final doc = _docOrNull;
    if (doc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precisas estar autenticado para guardar.')),
      );
      return;
    }

    setState(() => _saving = true);

    final phoneRaw = _phoneCtrl.text.trim();
    String? phoneE164;
    String? phoneIsoCode;
    String? phoneNsn;
    String? phoneCountryCode;

    if (phoneRaw.isNotEmpty) {
      try {
        final parsed = PhoneNumber.parse(
          phoneRaw,
          destinationCountry: _isoFromCountryCode(_selectedCountry?.isoCode),
        );
        phoneE164 = parsed.international;
        phoneIsoCode = parsed.isoCode.name;
        phoneNsn = parsed.nsn;
        phoneCountryCode = parsed.countryCode;
      } catch (_) {
        phoneE164 = phoneRaw;
      }
    }

    try {
      final nome = _nomeCtrl.text.trim();
      await doc.set(
        {
          'nome': nome,
          'displayName': nome,
          'bio': _bioCtrl.text.trim(),
          'country': _paisCtrl.text.trim(),
          'countryCode': _selectedCountry?.isoCode,
          'state': _estadoCtrl.text.trim(),
          'stateCode': _selectedState?.isoCode,
          'city': _cidadeCtrl.text.trim(),
          'phoneRaw': phoneRaw,
          if (phoneE164 != null) 'phoneE164': phoneE164,
          if (phoneIsoCode != null) 'phoneIsoCode': phoneIsoCode,
          if (phoneNsn != null) 'phoneNsn': phoneNsn,
          if (phoneCountryCode != null) 'phoneCountryCode': phoneCountryCode,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      try {
        await _auth.currentUser?.updateDisplayName(nome);
      } catch (_) {
        // ignore
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final doc = _docOrNull;
    final uid = _uidOrNull;
    if (doc == null || uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precisas estar autenticado para alterar a foto.')),
      );
      return;
    }

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final url = await _uploadBytes(
        bytes: bytes,
        path: 'users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: 'image/jpeg',
      );

      if (!mounted) return;
      setState(() => _photoUrl = url);

      await doc.set(
        {
          'photoUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      try {
        await _auth.currentUser?.updatePhotoURL(url);
      } catch (_) {
        // ignore
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar foto: $e')),
      );
    }
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String path,
    required String contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final meta = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, meta);
    return await ref.getDownloadURL();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sem sessao ativa. Faz login para ver o perfil.'),
          ),
        ),
      );
    }

    final canSave = !_saving;
    final hasStates = _statesForCountry.isNotEmpty;
    final cities = hasStates ? _citiesForState : _citiesForCountry;
    final stateLabel = _stateLabelForCountry(_selectedCountry);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Cliente'),
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(),
          const SizedBox(height: 20),
          _sectionTitle('Dados pessoais'),
          const SizedBox(height: 8),
          _field('Nome', _nomeCtrl, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _field('Bio', _bioCtrl, maxLines: 3, onChanged: (_) => setState(() {})),
          const SizedBox(height: 20),
          _sectionTitle('Contacto'),
          const SizedBox(height: 8),
          _phoneField(),
          const SizedBox(height: 20),
          _sectionTitle('Localizacao'),
          const SizedBox(height: 8),
          _countryField(),
          const SizedBox(height: 12),
          if (hasStates)
            _stateField(stateLabel)
          else
            _field(stateLabel, _estadoCtrl),
          const SizedBox(height: 12),
          _cityField(
            cities: cities,
            label: 'Cidade',
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }

  Widget _header() {
    final name = _nomeCtrl.text.trim();
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C';
    final hasPhoto = _photoUrl != null && _photoUrl!.startsWith('http');

    return Row(
      children: [
        InkWell(
          onTap: () {
            if (hasPhoto) {
              MediaViewerScreen.open(
                context,
                urls: <String>[_photoUrl!],
                title: 'Foto de perfil',
              );
            } else {
              _pickAndUploadProfilePhoto();
            }
          },
          onLongPress: _pickAndUploadProfilePhoto,
          child: CircleAvatar(
            radius: 34,
            backgroundImage: hasPhoto ? NetworkImage(_photoUrl!) : null,
            child: !hasPhoto ? Text(initials) : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Sem nome' : name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _bioCtrl.text.trim().isEmpty ? 'Sem bio' : _bioCtrl.text.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _pickAndUploadProfilePhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Alterar foto'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _phoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          decoration: InputDecoration(
            labelText: 'Telefone',
            hintText: _dialCode.isNotEmpty ? 'Ex: $_dialCode 82 123 4567' : 'Ex: +258 82 123 4567',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_selectedCountry != null && _dialCode.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Pais detectado: ${_selectedCountry!.name} ($_dialCode)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
      ],
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
        return _countries.where((c) => LocationDataService.normalize(c.name).contains(q)).take(20);
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
    required String label,
  }) {
    return RawAutocomplete<csc.City>(
      textEditingController: _cidadeCtrl,
      focusNode: _cidadeFocus,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (TextEditingValue value) {
        if (cities.isEmpty) return const Iterable<csc.City>.empty();
        final q = LocationDataService.normalize(value.text);
        if (q.isEmpty) return cities.take(20);
        return cities.where((c) => LocationDataService.normalize(c.name).contains(q)).take(20);
      },
      onSelected: (c) => setState(() => _cidadeCtrl.text = c.name),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
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
                    onPressed: () async {
                      if (cities.isEmpty) return;
                      final selected = await _showSearchBottomSheet<csc.City>(
                        title: 'Escolher cidade',
                        hintText: 'Escreve para pesquisar',
                        items: cities,
                        label: (c) => c.name,
                        maxResults: 300,
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
}

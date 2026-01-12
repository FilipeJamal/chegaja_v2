// lib/features/prestador/prestador_perfil_screen.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:country_state_city/country_state_city.dart' hide State;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:chegaja_v2/core/services/location_data_service.dart';
import 'package:chegaja_v2/features/common/widgets/media_viewer_screen.dart';

class PrestadorPerfilScreen extends StatefulWidget {
  const PrestadorPerfilScreen({super.key});

  @override
  State<PrestadorPerfilScreen> createState() => _PrestadorPerfilScreenState();
}

class _PrestadorPerfilScreenState extends State<PrestadorPerfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _cidadeCtrl = TextEditingController();
  final TextEditingController _paisCtrl = TextEditingController();

  final FocusNode _cidadeFocus = FocusNode();
  final FocusNode _paisFocus = FocusNode();

  // ----------------------------
  // Países / Cidades (autocomplete)
  // ----------------------------
  List<Country> _countries = <Country>[];
  List<City> _citiesForSelectedCountry = <City>[];
  Country? _selectedCountry;
  String? _profileCountryCode;
  bool _loadingCountries = false;
  bool _loadingCities = false;

  bool _loading = true;
  bool _saving = false;

  String? _photoUrl;
  List<String> _portfolioUrls = <String>[];

  double _radiusKm = 10;

  Future<void> _openImageViewer({
    required List<String> urls,
    int initialIndex = 0,
    String? title,
  }) async {
    if (!mounted) return;
    if (urls.isEmpty) return;

    await MediaViewerScreen.open(
      context,
      urls: urls,
      initialIndex: initialIndex,
      title: title,
    );
  }

  String? get _uidOrNull => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _docOrNull {
    final uid = _uidOrNull;
    if (uid == null) return null;
    return _db.collection('prestadores').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadCountries();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _bioCtrl.dispose();
    _cidadeCtrl.dispose();
    _paisCtrl.dispose();
    _cidadeFocus.dispose();
    _paisFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc = _docOrNull;

    // Evita crash se ainda não houver user autenticado (ou auth ainda a iniciar)
    if (doc == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final snap = await doc.get();
      final data = snap.data() ?? <String, dynamic>{};

      _nomeCtrl.text = (data['nome'] ?? data['displayName'] ?? '').toString();
      _bioCtrl.text = (data['bio'] ?? '').toString();
      _cidadeCtrl.text = (data['city'] ?? '').toString();
      _paisCtrl.text = (data['country'] ?? '').toString();

      _profileCountryCode = (data['countryCode'] as String?)?.trim();
      if (_profileCountryCode != null && _profileCountryCode!.isEmpty) {
        _profileCountryCode = null;
      }

      _photoUrl = (data['photoUrl'] as String?) ?? (data['fotoUrl'] as String?);

      final raw = (data['portfolioUrls'] as List?) ?? <dynamic>[];
      _portfolioUrls = raw.map((e) => e.toString()).toList();

      final rk = data['radiusKm'];
      if (rk is num) _radiusKm = rk.toDouble();

      // se já tivermos a lista de países carregada, seleciona o país
      // e carrega as cidades (para autocomplete do campo "Cidade")
      _syncSelectedCountryFromProfileOrText();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ------------------------------------------------------------
  // Países / Cidades (autocomplete)
  // ------------------------------------------------------------

  Future<void> _loadCountries() async {
    if (_loadingCountries) return;
    setState(() => _loadingCountries = true);

    try {
      final list = await LocationDataService.instance.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = list;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _countries = <Country>[]);
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }

    // depois de carregar países, tenta selecionar (profile ou texto)
    _syncSelectedCountryFromProfileOrText();
  }

  Future<void> _syncSelectedCountryFromProfileOrText() async {
    if (_countries.isEmpty) return;

    Country? found;

    // 1) prioridade: countryCode vindo do perfil
    final code = _profileCountryCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      try {
        found = _countries.firstWhere((c) => c.isoCode.toUpperCase() == code);
      } catch (_) {
        found = null;
      }
    }

    // 2) fallback: pelo nome escrito no campo
    found ??= await LocationDataService.instance.findCountryByName(_paisCtrl.text);

    if (found == null) return;

    final previous = _selectedCountry?.isoCode;
    final changed = previous == null || previous != found.isoCode;

    if (!mounted) return;
    setState(() {
      _selectedCountry = found;
      _paisCtrl.text = found!.name;
      _profileCountryCode = found.isoCode;
    });

    if (changed || _citiesForSelectedCountry.isEmpty) {
      await _loadCitiesForCountry(found.isoCode);
    }
  }

  Future<void> _loadCitiesForCountry(String countryCode) async {
    if (_loadingCities) return;
    if (countryCode.trim().isEmpty) return;

    setState(() => _loadingCities = true);
    try {
      final list = await LocationDataService.instance.getCitiesForCountryCode(countryCode);

      // remove duplicados por nome (há países com cidades repetidas)
      final seen = <String>{};
      final unique = <City>[];
      for (final c in list) {
        final key = LocationDataService.normalize(c.name);
        if (key.isEmpty) continue;
        if (seen.contains(key)) continue;
        seen.add(key);
        unique.add(c);
      }

      if (!mounted) return;
      setState(() {
        _citiesForSelectedCountry = unique;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _citiesForSelectedCountry = <City>[]);
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _onCountrySelected(Country c) async {
    final prev = _selectedCountry?.isoCode;
    final changed = prev == null || prev != c.isoCode;

    setState(() {
      _selectedCountry = c;
      _profileCountryCode = c.isoCode;
      _paisCtrl.text = c.name;
      if (changed) {
        _cidadeCtrl.clear();
        _citiesForSelectedCountry = <City>[];
      }
    });

    await _loadCitiesForCountry(c.isoCode);
  }

  Future<T?> _showSearchBottomSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    String hintText = 'Pesquisar…',
    int maxResults = 300,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final searchCtrl = TextEditingController();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final q = LocationDataService.normalize(searchCtrl.text);

                final filtered = <T>[];
                if (q.isEmpty) {
                  // mostra só um subset para não travar
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

  Future<void> _openCountryPicker() async {
    if (_loadingCountries) return;

    if (_countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista de países ainda a carregar…')),
      );
      return;
    }

    final selected = await _showSearchBottomSheet<Country>(
      title: 'Escolher país',
      hintText: 'Escreve para pesquisar países…',
      items: _countries,
      label: (c) => c.name,
      maxResults: 200,
    );

    if (selected != null) {
      await _onCountrySelected(selected);
    }
  }

  Future<void> _openCityPicker() async {
    final c = _selectedCountry;
    if (c == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolhe primeiro um país.')),
      );
      return;
    }

    if (_citiesForSelectedCountry.isEmpty && !_loadingCities) {
      await _loadCitiesForCountry(c.isoCode);
    }

    if (!mounted) return;

    final selected = await _showSearchBottomSheet<City>(
      title: 'Escolher cidade (${c.name})',
      hintText: 'Escreve para pesquisar cidades…',
      items: _citiesForSelectedCountry,
      label: (city) => city.name,
      maxResults: 400,
    );

    if (selected != null) {
      setState(() {
        _cidadeCtrl.text = selected.name;
      });
    }
  }

  Future<void> _save() async {
    final doc = _docOrNull;
    if (doc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precisas estar autenticado para guardar o perfil.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final code = (_selectedCountry?.isoCode ?? _profileCountryCode)?.trim();

      await doc.set({
        'nome': _nomeCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'city': _cidadeCtrl.text.trim(),
        'country': _paisCtrl.text.trim(),
        if (code != null && code.isNotEmpty)
          'countryCode': code.toUpperCase()
        else
          'countryCode': FieldValue.delete(),
        'radiusKm': _radiusKm,
        'photoUrl': _photoUrl,
        'portfolioUrls': _portfolioUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;

      final bytes = await x.readAsBytes();
      final url = await _uploadBytes(
        bytes: bytes,
        path: 'prestadores/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: 'image/jpeg',
      );

      if (!mounted) return;
      setState(() => _photoUrl = url);

      await doc.set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar foto: $e')),
      );
    }
  }

  Future<void> _addPortfolioImages() async {
    final doc = _docOrNull;
    final uid = _uidOrNull;

    if (doc == null || uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precisas estar autenticado para editar o portfólio.')),
      );
      return;
    }

    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;

      final newUrls = <String>[];

      for (final x in files) {
        final Uint8List bytes = await x.readAsBytes();
        final url = await _uploadBytes(
          bytes: bytes,
          path:
              'prestadores/$uid/portfolio/item_${DateTime.now().millisecondsSinceEpoch}_${x.name}.jpg',
          contentType: 'image/jpeg',
        );

        newUrls.add(url);
      }

      if (!mounted) return;
      setState(() => _portfolioUrls.addAll(newUrls));

      await doc.set({
        'portfolioUrls': _portfolioUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar imagens: $e')),
      );
    }
  }

  Future<void> _removePortfolioImage(String url) async {
    final doc = _docOrNull;
    if (doc == null) return;

    try {
      setState(() => _portfolioUrls.remove(url));

      await doc.set({
        'portfolioUrls': _portfolioUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // tenta apagar do Storage (se der)
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (_) {
        // ignora
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover imagem: $e')),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // evita crash se entrar aqui sem auth (ex.: web refresh / auth ainda a carregar)
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sem sessão ativa. Faz login para veres/editares o teu perfil.'),
          ),
        ),
      );
    }

    final canSave = !_saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Prestador'),
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
          const SizedBox(height: 16),
          _field('Nome', _nomeCtrl),
          const SizedBox(height: 12),
          _field('Bio', _bioCtrl, maxLines: 3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _cidadeAutocompleteField()),
              const SizedBox(width: 12),
              Expanded(child: _paisAutocompleteField()),
            ],
          ),
          const SizedBox(height: 16),
          _radius(),
          const SizedBox(height: 24),
          _portfolio(),
        ],
      ),
    );
  }

  Widget _header() {
    final initials = (_nomeCtrl.text.trim().isNotEmpty)
        ? _nomeCtrl.text.trim().substring(0, 1).toUpperCase()
        : 'P';

    final hasPhoto = (_photoUrl != null && _photoUrl!.startsWith('http'));

    return Row(
      children: [
        InkWell(
          // ✅ Tap abre a foto em ecrã inteiro (se existir). Long-press mantém “alterar foto”.
          onTap: () {
            if (hasPhoto) {
              _openImageViewer(
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
                _nomeCtrl.text.trim().isEmpty ? 'Sem nome' : _nomeCtrl.text.trim(),
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

  // ------------------------------------------------------------
  // UI: País / Cidade com sugestões (tipo WhatsApp/Instagram)
  // ------------------------------------------------------------

  Widget _paisAutocompleteField() {
    return RawAutocomplete<Country>(
      textEditingController: _paisCtrl,
      focusNode: _paisFocus,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (TextEditingValue value) {
        if (_countries.isEmpty) return const Iterable<Country>.empty();

        final q = LocationDataService.normalize(value.text);
        if (q.isEmpty) {
          return _countries.take(20);
        }

        return _countries
            .where((c) => LocationDataService.normalize(c.name).contains(q))
            .take(20);
      },
      onSelected: (c) => _onCountrySelected(c),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'País',
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
                    tooltip: 'Ver lista de países',
                    onPressed: _openCountryPicker,
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
          ),
          onChanged: (txt) {
            final sel = _selectedCountry;
            if (sel == null) return;

            final same = LocationDataService.normalize(txt) ==
                LocationDataService.normalize(sel.name);

            if (!same) {
              setState(() {
                _selectedCountry = null;
                _profileCountryCode = null;
                _citiesForSelectedCountry = <City>[];
              });
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _autocompleteOptionsView<Country>(
          context,
          onSelected,
          options,
          (c) => c.name,
        );
      },
    );
  }

  Widget _cidadeAutocompleteField() {
    return RawAutocomplete<City>(
      textEditingController: _cidadeCtrl,
      focusNode: _cidadeFocus,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (TextEditingValue value) {
        if (_selectedCountry == null) return const Iterable<City>.empty();
        if (_citiesForSelectedCountry.isEmpty) return const Iterable<City>.empty();

        final q = LocationDataService.normalize(value.text);
        if (q.isEmpty) {
          return _citiesForSelectedCountry.take(20);
        }

        return _citiesForSelectedCountry
            .where((c) => LocationDataService.normalize(c.name).contains(q))
            .take(20);
      },
      onSelected: (c) => setState(() => _cidadeCtrl.text = c.name),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        final hasCountry = _selectedCountry != null;

        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Cidade',
            hintText: hasCountry ? null : 'Escreve manualmente ou escolhe um país',
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
                    tooltip: hasCountry
                        ? 'Ver lista de cidades'
                        : 'Escolhe um país para ver cidades',
                    onPressed: hasCountry ? _openCityPicker : null,
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _autocompleteOptionsView<City>(
          context,
          onSelected,
          options,
          (c) => c.name,
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
    final list = options.toList();
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final opt = list[index];
              return ListTile(
                dense: true,
                title: Text(label(opt)),
                onTap: () => onSelected(opt),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _radius() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Raio de atuação (km)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _radiusKm.clamp(1, 50),
                min: 1,
                max: 50,
                divisions: 49,
                label: '${_radiusKm.round()} km',
                onChanged: (v) => setState(() => _radiusKm = v),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                '${_radiusKm.round()} km',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _portfolio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Portfólio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),

            // ✅ FIX: não usar Size.fromHeight / width infinita dentro de Row
            ElevatedButton.icon(
              onPressed: _addPortfolioImages,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48), // largura automática
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_portfolioUrls.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Ainda não tens imagens no portfólio.\n'
              'Carrega algumas para o cliente ver os teus trabalhos.',
              textAlign: TextAlign.center,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _portfolioUrls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, i) {
              final url = _portfolioUrls[i];

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ✅ Tap para abrir em ecrã inteiro
                    InkWell(
                      onTap: () => _openImageViewer(
                        urls: _portfolioUrls,
                        initialIndex: i,
                        title: 'Portfólio',
                      ),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => _removePortfolioImage(url),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            // ✅ Evita warning do withOpacity (usa alpha direto)
                            color: Colors.black.withAlpha(153),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

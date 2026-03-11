import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/user_country_service.dart';
import 'package:chegaja_v2/core/services/location_data_service.dart';
import 'package:country_state_city/country_state_city.dart' as csc;

class RegionSelectionWidget extends StatefulWidget {
  final VoidCallback? onRegionSelected;

  const RegionSelectionWidget({super.key, this.onRegionSelected});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: const RegionSelectionWidget(),
        ),
      ),
    );
  }

  @override
  State<RegionSelectionWidget> createState() => _RegionSelectionWidgetState();
}

class _RegionSelectionWidgetState extends State<RegionSelectionWidget> {
  String? _currentRegion;
  bool _loadingCountries = true;
  bool _loadingRegion = true;
  final List<csc.Country> _countries = [];
  bool get _isLoading => _loadingCountries || _loadingRegion;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<csc.Country> get _filteredCountries {
    if (_searchQuery.trim().isEmpty) return _countries;
    final query = LocationDataService.normalize(_searchQuery);
    if (query.isEmpty) return _countries;
    return _countries.where((country) {
      final name = LocationDataService.normalize(country.name);
      final code = country.isoCode.toUpperCase();
      return name.contains(query) || code.contains(query.toUpperCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentRegion();
    _loadCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentRegion() async {
    try {
      final region = await AuthService.getUserRegion();
      if (mounted) {
        setState(() {
          _currentRegion = (region ?? 'PT').toUpperCase(); // Default fallback
          _loadingRegion = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRegion = false);
    }
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await LocationDataService.instance.getCountries();
      if (mounted) {
        setState(() {
          _countries
            ..clear()
            ..addAll(countries);
          _loadingCountries = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  Future<void> _selectRegion(String code) async {
    setState(() => _loadingRegion = true);
    try {
      await AuthService.updateUserRegion(code);
      await UserCountryService.instance.setManualCountry(code);
      if (mounted) {
        setState(() {
          _currentRegion = code;
          _loadingRegion = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Região definida para: $code')),
        );

        Navigator.pop(context);
        widget.onRegionSelected?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRegion = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao definir região: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecionar País / Região',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Isto ajuda a encontrar endereços e prestadores perto de ti.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Pesquisar país ou código',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: _filteredCountries.isEmpty
                  ? const Center(child: Text('Nenhum resultado.'))
                  : ListView.separated(
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final code = country.isoCode.toUpperCase();
                        final isSelected = _currentRegion == code;
                        final flag = country.flag.trim();

                        return ListTile(
                          leading: Text(
                            flag.isNotEmpty ? flag : code,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(country.name),
                          subtitle: Text(code),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.circle_outlined,
                                  color: Colors.grey),
                          onTap: () => _selectRegion(code),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? const BorderSide(
                                    color: Colors.green, width: 2)
                                : BorderSide.none,
                          ),
                          tileColor: isSelected
                              ? Colors.green.withValues(alpha: 0.05)
                              : null,
                        );
                      },
                    ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteiro/roteiro.dart';

const String _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
const int _stressCount = int.fromEnvironment('ROTEIRO_STRESS');

void main() {
  runApp(const RoteiroExampleApp());
}

class RoteiroExampleApp extends StatelessWidget {
  const RoteiroExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roteiro PoC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38D2C0),
        ),
      ),
      home: const RoteiroDemoPage(),
    );
  }
}

class RoteiroDemoPage extends StatefulWidget {
  const RoteiroDemoPage({super.key});

  @override
  State<RoteiroDemoPage> createState() => _RoteiroDemoPageState();
}

class _RoteiroDemoPageState extends State<RoteiroDemoPage> {
  late final RoteiroMapController _mapController;
  late final RoteiroStore _store;

  @override
  void initState() {
    super.initState();
    _mapController = RoteiroMapController(
      initialZoom: 12,
      onError: _showError,
      // Mesma verificação de disponibilidade do Gestão/BackOffice.
      // Sem chave, libera o botão e deixa o plugin nativo decidir.
      streetViewService: _googleMapsApiKey.isEmpty
          ? const AlwaysAvailableStreetViewService()
          : GoogleStreetViewService(apiKey: _googleMapsApiKey),
    );
    _store = RoteiroStore(
      // Opção que liga a edição dos pontos do roteiro. Desligada por padrão
      // no pacote; aqui habilitamos para a demo.
      editableVisits: true,
      onSaveVisit: (change) async {
        // Simula a persistência que cada app fará (API/Sodata/SQLite).
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_stressCount > 0) _store.showRoute = false;
      unawaited(
        _store.setClients(
          _stressCount > 0 ? _stressClients(_stressCount) : _mockClients(),
        ),
      );
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _editVisit(RoteiroClient client) async {
    final change = await RoteiroVisitDialog.show(context, client);
    if (change == null || !mounted) return;

    final saved = await _store.saveVisit(change);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Visita atualizada.' : 'Não foi possível atualizar a visita.',
        ),
      ),
    );
  }

  void _select(RoteiroClient client) {
    _store.select(client);
    final coordinate = client.coordinate;
    if (coordinate != null) {
      _mapController.focusOn(
        LatLng(coordinate.latitude, coordinate.longitude),
      );
    }
  }

  Future<void> _openFilters() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RoteiroFilterPanel(
        store: _store,
        onClose: () {
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _openClients() {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.62,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: RoteiroClientList(
                  clients: _store.visibleClients,
                  selected: _store.selected,
                  onTap: (client) {
                    Navigator.pop(sheetContext);
                    _select(client);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final selected = _store.selected;
        final coordinate = selected?.coordinate;
        final streetViewTarget = coordinate == null
            ? null
            : LatLng(coordinate.latitude, coordinate.longitude);

        return Scaffold(
          body: RoteiroMap(
            controller: _mapController,
            markers: _store.markers,
            polylines: _store.showRoute ? _store.polylines : const <Polyline>{},
            titles: _store.titles,
            initialTarget: const LatLng(-8.0578, -34.8829),
            initialZoom: 12,
            streetViewTarget: streetViewTarget,
            infoWindow: selected == null
                ? null
                : RoteiroInfoWindowData(
                    title: selected.displayName,
                    subtitle: selected.address,
                    rows: selected.toView(),
                  ),
            onCloseInfoWindow: _store.clearSelection,
            onEditInfoWindow: selected == null || !_store.editableVisits
                ? null
                : () => _editVisit(selected),
            detailsCard: selected == null
                ? null
                : RoteiroDetailsCard(
                    title: selected.displayName,
                    address: selected.address,
                    subtitle: [
                      selected.day?.title,
                      selected.periodicity?.label,
                    ].whereType<String>().join(' · '),
                    onClose: _store.clearSelection,
                    onStreetView: streetViewTarget == null
                        ? null
                        : () => _mapController.openStreetView(
                              streetViewTarget,
                            ),
                  ),
            showDetailsCard: selected != null,
            customButton: RoteiroMapButton(
              icon: Icons.tune,
              tooltip: 'Filtros',
              active: !_store.filter.isEmpty,
              onTap: _openFilters,
            ),
            customButtonRight: RoteiroMapButton(
              icon: Icons.list_alt_outlined,
              tooltip: 'Clientes',
              onTap: _openClients,
            ),
            onMapTap: (_) => _store.clearSelection(),
          ),
          floatingActionButton: _store.isLoading
              ? const FloatingActionButton(
                  onPressed: null,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        );
      },
    );
  }
}

RoteiroClient _client({
  required String code,
  required String name,
  required String address,
  required VisityDay day,
  required Periodicity periodicity,
  required bool firstWeek,
  required int visitOrder,
  required double lat,
  required double lon,
  DateTime? dateBase,
}) {
  return RoteiroClient(
    personCode: code,
    name: name,
    fantasy: name,
    cnpj: '00.000.000/0001-00',
    address: address,
    municipality: 'Recife',
    representativeName: 'Ana Souza',
    day: day,
    periodicity: periodicity,
    firstWeek: firstWeek,
    visitOrder: visitOrder,
    lat: lat,
    lon: lon,
    dateBase: dateBase ?? DateTime(2026, 11, 10),
    lastPurchase: DateTime(2026, 10, 28),
  );
}

List<RoteiroClient> _stressClients(int count) {
  final random = math.Random(42);
  const days = [
    VisityDay.monday,
    VisityDay.tuesday,
    VisityDay.wednesday,
    VisityDay.thursday,
    VisityDay.friday,
  ];
  return List.generate(count, (i) {
    final dense = i.isEven;
    final lat = dense
        ? -8.05 + (random.nextDouble() - 0.5) * 0.4
        : -3.0 - random.nextDouble() * 10;
    final lon = dense
        ? -34.90 + (random.nextDouble() - 0.5) * 0.4
        : -35.0 - random.nextDouble() * 10;
    return _client(
      code: '${10000 + i}',
      name: 'Cliente ${i + 1}',
      address: 'Rua Teste, ${i + 1}',
      day: days[i % days.length],
      periodicity: Periodicity.weekly,
      firstWeek: true,
      visitOrder: i + 1,
      lat: lat,
      lon: lon,
    );
  });
}

List<RoteiroClient> _mockClients() {
  return [
    // Segunda, quinzena 1/3.
    _client(
      code: '1001',
      name: 'Mercado Boa Vista',
      address: 'Rua da Aurora, 100',
      day: VisityDay.monday,
      periodicity: Periodicity.fortnightly,
      firstWeek: true,
      visitOrder: 1,
      lat: -8.0550,
      lon: -34.8850,
    ),
    _client(
      code: '1002',
      name: 'Padaria Aurora',
      address: 'Rua da Aurora, 250',
      day: VisityDay.monday,
      periodicity: Periodicity.fortnightly,
      firstWeek: true,
      visitOrder: 2,
      lat: -8.0520,
      lon: -34.8810,
    ),
    // Segunda, quinzena 2/4.
    _client(
      code: '1003',
      name: 'Farmácia Central',
      address: 'Av. Conde da Boa Vista, 400',
      day: VisityDay.monday,
      periodicity: Periodicity.fortnightly,
      firstWeek: false,
      visitOrder: 1,
      lat: -8.0580,
      lon: -34.8790,
    ),
    _client(
      code: '1004',
      name: 'Loja do Centro',
      address: 'Rua Nova, 80',
      day: VisityDay.monday,
      periodicity: Periodicity.fortnightly,
      firstWeek: false,
      visitOrder: 2,
      lat: -8.0600,
      lon: -34.8760,
    ),
    // Terça.
    _client(
      code: '1005',
      name: 'Supermercado Recife',
      address: 'Av. Agamenon Magalhães, 900',
      day: VisityDay.tuesday,
      periodicity: Periodicity.weekly,
      firstWeek: false,
      visitOrder: 1,
      lat: -8.0520,
      lon: -34.8900,
    ),
    _client(
      code: '1006',
      name: 'Casa & Cia',
      address: 'Rua do Riachuelo, 320',
      day: VisityDay.tuesday,
      periodicity: Periodicity.weekly,
      firstWeek: false,
      visitOrder: 2,
      lat: -8.0500,
      lon: -34.8930,
    ),
    // Quarta.
    _client(
      code: '1007',
      name: 'Pet Shop Amigo',
      address: 'Rua dos Palmares, 45',
      day: VisityDay.wednesday,
      periodicity: Periodicity.monthly,
      firstWeek: false,
      visitOrder: 1,
      lat: -8.0640,
      lon: -34.8880,
    ),
    _client(
      code: '1008',
      name: 'Ótica Visão',
      address: 'Av. Guararapes, 210',
      day: VisityDay.wednesday,
      periodicity: Periodicity.monthly,
      firstWeek: false,
      visitOrder: 2,
      lat: -8.0620,
      lon: -34.8840,
    ),
    // Quinta.
    _client(
      code: '1009',
      name: 'Bazar Popular',
      address: 'Rua da Concórdia, 55',
      day: VisityDay.thursday,
      periodicity: Periodicity.days21,
      firstWeek: false,
      visitOrder: 1,
      lat: -8.0590,
      lon: -34.8910,
    ),
    _client(
      code: '1010',
      name: 'Livraria Cultura',
      address: 'Rua do Hospício, 150',
      day: VisityDay.thursday,
      periodicity: Periodicity.days21,
      firstWeek: false,
      visitOrder: 2,
      lat: -8.0560,
      lon: -34.8890,
    ),
    // Sexta.
    _client(
      code: '1011',
      name: 'Restaurante Sabor',
      address: 'Rua da Praia, 12',
      day: VisityDay.friday,
      periodicity: Periodicity.weekly,
      firstWeek: false,
      visitOrder: 1,
      lat: -8.0490,
      lon: -34.8860,
    ),
    _client(
      code: '1012',
      name: 'Café do Porto',
      address: 'Cais do Apolo, 300',
      day: VisityDay.friday,
      periodicity: Periodicity.weekly,
      firstWeek: false,
      visitOrder: 2,
      lat: -8.0470,
      lon: -34.8830,
    ),
    // Sem dia de visita (entra com "Sem agendamento" ligado).
    RoteiroClient(
      personCode: '1013',
      name: 'Cliente Sem Agenda',
      fantasy: 'Sem Agenda',
      address: 'Rua sem dia definido, 10',
      visitOrder: 9,
      lat: -8.0700,
      lon: -34.8700,
    ),
    // Sem coordenada: aparece na lista, não no mapa nem na rota.
    RoteiroClient(
      personCode: '1014',
      name: 'Cliente Sem Coordenada',
      fantasy: 'Sem Coordenada',
      address: 'Endereço ainda não geocodificado',
      day: VisityDay.monday,
      periodicity: Periodicity.weekly,
      visitOrder: 3,
    ),
  ];
}

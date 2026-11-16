# roteiro

Componente compartilhado de **Roteiro** para EASYMART, Gestão e BackOffice:
mapa, marcadores por dia/periodicidade, títulos flutuantes, polylines (OSRM),
filtros, lista de clientes, card de detalhes e Street View.

É um **PoC** da Fase 0 + 1 do plano de unificação: a camada de mapa foi
extraída do EASYMART/Gestão (onde já era ~91–99% o mesmo código) e ganhou um
store e um modelo canônico para provar o desenho ponta a ponta.

- Android e Web com o mesmo código Dart.
- `google_maps_flutter` (Web via implementação oficial `google_maps_flutter_web`).
- Street View nativo Android (fork do Gestão) com verificação de disponibilidade; no Web, fallback com link para o Google Maps.
- 42 testes de núcleo/store/edição/street view passando; `flutter analyze` limpo; `flutter build web` OK.

---

## Estrutura

```
lib/
  core.dart                  # núcleo puro (sem Flutter)
  ui.dart                    # mapa/widgets/store
  roteiro.dart               # barrel completo
  src/
    core/
      geo_point.dart         # coordenada + normalização (corrige -235489337.0)
      visity_day.dart        # dias + assets canônicos
      periodicity.dart       # periodicidade + filtro quinzenal 1/3 e 2/4
      roteiro_client.dart    # modelo canônico
      roteiro_filter.dart    # regras de filtro compartilhadas
      roteiro_visit_change.dart # edição de um ponto do roteiro
      route_planner.dart     # agrupa por dia/quinzena e ordena por visita
      osrm_route_service.dart
    ui/
      map/roteiro_map.dart           # mapa + overlay + fullscreen + street view
      map/roteiro_map_controller.dart# câmera, clustering, tipo de mapa
      store/roteiro_store.dart       # marcadores/títulos/polylines
      store/roteiro_marker_factory.dart
      store/roteiro_title_factory.dart
      widgets/...                    # filtros, lista, info window, card, edição
      platform/street_view_*.dart    # adapter Web / mobile / stub
assets/
  map_style.txt              # idêntico nos 3 apps (mesmo MD5)
  images/monitoramento/...   # 55 ícones (dia + periodicidade)
example/                     # app demo Android/Web
test/                        # núcleo + store
```

Regra de dependência: `core` não importa Flutter; `ui` importa `core`;
nenhuma camada importa `dart:io`, `sqlite`, `path_provider` ou `file_picker`.

---

## Como rodar

### Testes e análise

```bash
flutter pub get
flutter analyze
flutter test
```

### Web

O `google_maps_flutter_web` **não injeta** o script do Maps; ele precisa estar
no `index.html`.

1. Edite `example/web/index.html` e troque `YOUR_GOOGLE_MAPS_API_KEY` por uma
   chave com **Maps JavaScript API** habilitada (restrita por HTTP referrer:
   `localhost` e o domínio de produção).
2. Rode:

```bash
cd example
flutter pub get
flutter run -d chrome
# ou
flutter build web
```

### Android

1. Edite `example/android/app/src/main/AndroidManifest.xml` e troque
   `YOUR_GOOGLE_MAPS_API_KEY` por uma chave com **Maps SDK for Android**
   habilitada (restrição por package/SHA-1).
2. Rode:

```bash
cd example
flutter run -d <device> \
  --dart-define=GOOGLE_MAPS_API_KEY=<mesma-chave>
```

O `--dart-define` é opcional: sem ele, o pacote usa
`AlwaysAvailableStreetViewService` e o plugin nativo decide. Com ele, a
disponibilidade é verificada na Street View Metadata API (é preciso ter a
**Street View Static API** habilitada no projeto).

> O build Android não foi executado neste ambiente de PoC (o sandbox não tinha
> JDK 17/21 + Gradle cache gravável). O plugin é o mesmo já usado no BackOffice;
> o `example` está configurado com o manifest.

---

## Uso nos apps

### Dependência

Enquanto o repo do pacote não existe, use path:

```yaml
dependencies:
  roteiro:
    path: ../roteiro
```

Depois, a ideia é tag + Git:

```yaml
dependencies:
  roteiro:
    git:
      url: https://github.com/EasymartTecnologia/roteiro.git
      ref: v0.2.0
```

Para desenvolver junto, sem commitar:

```yaml
# pubspec_overrides.yaml
dependency_overrides:
  roteiro:
    path: ../roteiro
```

### Mapa

```dart
final mapController = RoteiroMapController(onError: showSnackBar);
final store = RoteiroStore();

await store.setClients(clientesMapeados);

RoteiroMap(
  controller: mapController,
  markers: store.markers,
  polylines: store.showRoute ? store.polylines : const <Polyline>{},
  titles: store.titles,
  initialTarget: const LatLng(-8.0578, -34.8829),
  initialZoom: 12,
  streetViewTarget: coordenadaSelecionada,
  infoWindow: selecionado == null
      ? null
      : RoteiroInfoWindowData(
          title: selecionado.displayName,
          subtitle: selecionado.address,
          rows: selecionado.toView(),
        ),
  onCloseInfoWindow: store.clearSelection,
  showDetailsCard: selecionado != null,
  detailsCard: selecionado == null
      ? null
      : RoteiroDetailsCard(
          title: selecionado.displayName,
          address: selecionado.address,
          onClose: store.clearSelection,
        ),
  onMapTap: (_) => store.clearSelection(),
)
```

### Editar pontos do roteiro

A edição é **opt-in** (`editableVisits: false` por padrão). Quando ligada, o
store aceita `RoteiroVisitChange` e persiste via `onSaveVisit`:

```dart
final store = RoteiroStore(
  editableVisits: true,
  onSaveVisit: (change) => repository.updateVisit(change),
);
```

O botão de editar (ícone de lápis) fica no **popup de detalhes do cliente**,
ao lado do nome/endereço:

```dart
RoteiroMap(
  // ...
  infoWindow: RoteiroInfoWindowData(
    title: selecionado.displayName,
    subtitle: selecionado.address,
    rows: selecionado.toView(),
  ),
  onCloseInfoWindow: store.clearSelection,
  onEditInfoWindow: store.editableVisits
      ? () async {
          final change = await RoteiroVisitDialog.show(context, selecionado);
          if (change != null) await store.saveVisit(change);
        }
      : null,
);
```

O diálogo edita **dia**, **frequência** (semanal, quinzenal 1/3 e 2/4, mensal,
21 dias), **ordem** e **data base**. O `saveVisit` atualiza a lista local,
marcadores, títulos e rotas; se `onSaveVisit` falhar, o estado anterior é
mantido e `errorMessage` é preenchido.

### Filtros

`RoteiroFilterPanel` reproduz o layout dos apps (checkbox em vez de chips):
toggles de nome/percurso/sequência/sem agendamento, dias com checkbox + ícone,
frequência e botões Limpar/Aplicar. Ele aceita um `agentSelector` opcional para
Gestão/BackOffice.

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => RoteiroFilterPanel(
    store: store,
    onClose: () => Navigator.pop(context),
  ),
);
```

### Mapeando o modelo de cada app

```dart
RoteiroClient fromScheduling(Scheduling s) => RoteiroClient(
      personCode: s.personCode,
      name: s.clientName,
      fantasy: s.fantasy,
      cnpj: s.cnpj,
      address: s.address,
      agentCode: s.agentCode,
      supervisorCode: s.supervisorCode,
      dateBase: s.dateBase,
      day: VisityDay.fromWeekDay(s.dayToVisity?.weekDay ?? 0),
      periodicity: Periodicity.fromCode(s.periodicity),
      firstWeek: s.firstWeek,
      visitOrder: s.visitOrder,
      lat: s.lat,
      lon: s.lon,
    );
```

### Street View (Android)

O pacote usa o **fork do Gestão** (`flutter_street_view`), que é o plugin que
compila no Android com AGP 8:

- `FlutterStreetView(latitude, longitude, zoom: -5, tilt: 10, bearing: 10)`;
- disponibilidade verificada na **Street View Metadata API**
  (`/maps/api/streetview/metadata`), como no Gestão/BackOffice.

> O BackOffice usa `flutter_google_street_view`, mas a versão 1.0.2 não declara
> `namespace` no `build.gradle` e quebra no AGP 8. Por isso o pacote adota o
> fork do Gestão. Se o app fizer questão do plugin do BackOffice, injete via
> `streetViewBuilder`.

```dart
const mapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

final mapController = RoteiroMapController(
  streetViewService: mapsKey.isEmpty
      ? const AlwaysAvailableStreetViewService()
      : GoogleStreetViewService(apiKey: mapsKey),
);
```

Sem chave, o botão é liberado e o plugin nativo decide. Com chave, pontos sem
cobertura retornam `RoteiroStreetViewResult.unavailable` e o mapa mostra
"Street View indisponível para este ponto.".

No **Web** não existe panorama nativo — mesma limitação do Gestão/BackOffice.
O fallback mostra a coordenada e o botão **Abrir no Google Maps**. Em **iOS**
o fork não tem implementação; o pacote mostra o placeholder (nativo disponível
no Android). Para outra plataforma/plugin, injete `streetViewBuilder`.

---

## Decisões do PoC

| Tema | Decisão |
|---|---|
| Modelo | `RoteiroClient` canônico; cada app mapeia em 1 arquivo |
| Filtros | `RoteiroFilter` no core + `RoteiroFilterPanel` com o layout dos apps |
| Rota | `RoutePlanner` + `RouteService`; OSRM é injetável |
| Estado | MobX, como os três apps |
| Cluster | skip por zoom (mesmo comportamento do EASYMART); trocável no futuro |
| Street View | nativo Android (fork do Gestão) + metadata; Web com fallback |
| Edição | opt-in (`editableVisits` + `onSaveVisit`), desligada por padrão |
| Assets | empacotados (`packages/roteiro/...`); `map_style.txt` único |
| Tela | **não** faz parte do pacote; cada app compõe a sua |

### O que ainda não está no PoC

- `RoteiroRepository`/OData por app (só o contrato conceitual no plano).
- Estatísticas, paginação, remoção de visita, drag de marcador/coordenada.
- Exportar/importar planilha (BackOffice).
- Offline/SQLite (EASYMART).
- Permissões, câmera, navegação externa.

Esses itens continuam no app, como descrito no documento de arquitetura da unificação.

---

## Limitações conhecidas

- **Chave do Maps**: sem uma chave válida o mapa não renderiza (Web precisa do
  script; Android precisa do meta-data).
- **Tela cheia**: abre um segundo `RoteiroMap` com um controller próprio (para
  não compartilhar câmera entre dois mapas). Em produção, vale evoluir para um
  controller multi-mapa.
- **OSRM público**: `router.project-osrm.org` não tem SLA; para produção,
  injete `baseUrl` próprio ou outro `RouteService`.
- **Street View no Web**: sem panorama nativo (como nos apps); o fallback abre
  o ponto no Google Maps.
- **Chave da metadata**: além da chave do mapa, a verificação de Street View
  usa a Street View Static API habilitada no projeto do Google Cloud.
- **Testes de mapa**: o PoC cobre núcleo/store/serviço; a renderização do Google
  Maps e o plugin nativo exigem chave/dispositivo e são validados manualmente.

---

## Próximos passos sugeridos

1. Levar o pacote para um repositório próprio (`EasymartTecnologia/roteiro`) e
   consumir por tag nos três apps.
2. Migrar o mapa do Gestão primeiro (é o mais completo), depois EASYMART e
   BackOffice.
3. Implementar `ODataRoteiroRepository` no Gestão/BackOffice e
   `LocalRoteiroRepository` no EASYMART.
4. Levar as features específicas (paginação, edição, drag, exportação) como
   flags/adapters, não como `if (app == ...)`.

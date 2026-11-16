# Changelog

## 0.2.0

- Edição opcional de pontos do roteiro: `editableVisits` + `onSaveVisit`,
  `RoteiroVisitChange`, `RoteiroVisitDialog` e ação de editar (lápis) no popup
  de detalhes do cliente.
- `RoteiroFilterPanel` com o layout dos apps (checkbox, dias com ícone,
  frequência, Limpar/Aplicar e slot opcional de representante).
- Street View nativo Android com o fork do Gestão (`flutter_street_view`),
  verificação na Street View Metadata API e fallback no Web para abrir o ponto
  no Google Maps. O plugin antigo do BackOffice não tem `namespace` e quebra
  no AGP 8.
- Testes de núcleo/store/edição/street view; 42 testes no total.

## 0.1.0

- PoC do componente de Roteiro compartilhado.
- Núcleo puro: `GeoPoint`, `VisityDay`, `Periodicity`, `RoteiroClient`,
  `RoteiroFilter`, `RoutePlanner`, `OsrmRouteService`.
- Mapa: `RoteiroMap`, `RoteiroMapController` (câmera, clustering, tipo de
  mapa, tela cheia) e overlay de botões/info window.
- Store MobX: marcadores, títulos flutuantes e polylines.
- Filtros, lista de clientes, card de detalhes e info window.
- Street View Web via `StreetViewPanorama` (JS interop) + adapter injetável
  para Android/iOS.
- Assets canônicos (dias, periodicidade, `map_style.txt`).
- 21 testes de núcleo/store e `example` Android/Web.

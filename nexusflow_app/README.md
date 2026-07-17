# nexusflow_app

App em Flutter (Android, iOS, Web e Windows) do sistema NEXUSflow — estoque, vendas (PDV) e relatórios. Consome a API do [`../nexusflow_backend`](../nexusflow_backend).

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.12`
- A API do backend rodando — veja o passo a passo em [`../nexusflow_backend/README.md`](../nexusflow_backend/README.md) (banco de dados + `dart_frog dev`) antes de continuar.

## 1. Instalar as dependências

```bash
flutter pub get
```

## 2. Rodar o app

Com a API já rodando (`http://localhost:8080` por padrão), liste os dispositivos disponíveis e rode:

```bash
flutter devices
flutter run
```

Por padrão o app aponta para:

- `http://localhost:8080` — Web e Windows
- `http://10.0.2.2:8080` — emulador Android (endereço que o emulador usa para chegar ao `localhost` da máquina host)

Veja `lib/core/api_config.dart` para os detalhes.

### Apontando para outro endereço

Se for testar em um **dispositivo físico** ou apontar para outra máquina/IP, sobrescreva a URL da API no build:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP:8080
```

## Getting Started (Flutter)

Este projeto é um app Flutter padrão. Recursos úteis se for sua primeira vez com Flutter:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

Para ajuda geral com desenvolvimento Flutter, veja a [documentação oficial](https://docs.flutter.dev/).

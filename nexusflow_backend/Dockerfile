# ============================================================
# Stage 1: Build — compila o servidor Dart Frog
# ============================================================
FROM dart:stable AS build

WORKDIR /app

# Copia os arquivos de dependências primeiro (cache de camadas)
COPY pubspec.yaml pubspec.lock* ./

# Instala dependências
RUN dart pub get

# Copia o restante do código-fonte
COPY . .

# Adiciona o pub-cache ao PATH para usar executáveis globais
ENV PATH="$PATH:/root/.pub-cache/bin"

# Instala o dart_frog_cli e faz o build de produção
RUN dart pub global activate dart_frog_cli
RUN dart_frog build

# Compila o servidor para um binário nativo
RUN dart compile exe build/bin/server.dart -o build/bin/server

# ============================================================
# Stage 2: Runtime — imagem mínima só com o binário
# ============================================================
FROM debian:bookworm-slim AS runtime

# Instala dependências mínimas de runtime
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia o binário compilado
COPY --from=build /app/build/bin/server /app/bin/server

# Copia os scripts SQL de migração (útil para inicialização)
COPY --from=build /app/scripts /app/scripts

# Porta padrão do Dart Frog
EXPOSE 8080

# Executa o servidor
CMD ["/app/bin/server"]

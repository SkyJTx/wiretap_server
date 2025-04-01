# Use Debian-based Dart SDK image.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
RUN curl -s https://raw.githubusercontent.com/objectbox/objectbox-dart/main/install.sh | bash

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .
RUN dart compile exe bin/wiretap_server.dart -o bin/wiretap_server

# Build minimal serving image using Debian slim.
FROM debian:bullseye-slim
WORKDIR /app
COPY --from=build /app/bin/wiretap_server /app/bin/wiretap_server

# Install necessary runtime dependencies.
RUN apt-get update && apt-get install -y \
    libserialport-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Start server.
EXPOSE 8080
CMD ["/app/bin/wiretap_server"]

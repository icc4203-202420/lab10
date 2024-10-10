# Usa la imagen oficial de Debian 10 (Buster)
FROM debian:buster

# Establece la carpeta de trabajo en /app
WORKDIR /app

# Actualiza los paquetes y dependencias
RUN apt-get update -y && \
    apt-get install -y \
    build-essential \
    patch \
    ruby-dev \
    zlib1g-dev \
    liblzma-dev \
    libsqlite3-dev \
    sqlite3 \
    curl \
    git \
    nodejs \
    yarn \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libreadline-dev \
    libssl-dev \
    libgmp-dev \
    libpq-dev \
    libffi-dev \
    libyaml-dev \
    tzdata

# Instala rbenv y ruby-build
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    ~/.rbenv/bin/rbenv init && \
    ~/.rbenv/plugins/ruby-build/install.sh

# Actualiza ruby-build
RUN cd ~/.rbenv/plugins/ruby-build && git pull

# Instala Ruby 2.7.8 utilizando rbenv y configura rbenv en el entorno de shell
RUN ~/.rbenv/bin/rbenv install 2.7.8 && \
    ~/.rbenv/bin/rbenv global 2.7.8 && \
    ~/.rbenv/bin/rbenv exec gem install bundler -v 2.4.22 && \
    ~/.rbenv/bin/rbenv rehash

# Agregar rbenv al PATH
ENV PATH="/root/.rbenv/shims:/root/.rbenv/bin:$PATH"

# Actualiza Rubygems a la versión más reciente compatible
RUN gem update --system 3.3.22

# Copia todos los archivos de la aplicación al contenedor
COPY . /app

# Instala las dependencias de gemas usando rbenv exec para asegurar el entorno
RUN ~/.rbenv/bin/rbenv exec bundle install

# Instala las dependencias del proyecto Rails usando rbenv inicializado
RUN ~/.rbenv/bin/rbenv exec bundle update nokogiri rails-dom-testing

# Ejecuta el comando para preparar la base de datos
RUN ~/.rbenv/bin/rbenv exec rails db:setup

# Expone el puerto 3000
EXPOSE 3000

# Comando para inicializar la base de datos y lanzar el servidor
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

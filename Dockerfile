# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.3.8
ARG NODE_VERSION=20.19.2
ARG YARN_VERSION=1.22.22

# Step 1: Builder base (Install environment)
FROM docker.io/library/ruby:$RUBY_VERSION-bookworm AS builder-base

ARG APP_STAGE
ARG NODE_VERSION
ARG YARN_VERSION

WORKDIR /app

# Install build-time packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      git \
      libpq-dev \
      tzdata \
      node-gyp \
      pkg-config \
      python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set development environment
ENV RAILS_ENV=development \
    NODE_ENV=development \
    BUNDLE_PATH=".bundle" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    PATH=/usr/local/node/bin:$PATH

# Install JavaScript dependencies
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Step 2: Build stage (Copy config)
FROM builder-base AS build

# Install application gems
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install --path .bundle

# Install node modules
COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install --immutable && yarn add yarn@$YARN_VERSION

# Copy config vite
COPY app/frontend ./app/frontend
COPY vite.config.mts ./

# Copy application codevolumes:
  postgresdata:
  valkeydata:
  node_modules:
  bundler:

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
      POSTGRES_ROOT_HOST: "%"
      POSTGRES_START_TIMEOUT: 60
    ports:
      - 5432:5432
    volumes:
      - postgresdata:/var/lib/postgresql/data

# redis
  valkey:
    image: valkey/valkey:8.1.3-alpine
    ports:
      - 6379:6379
    volumes:
      - valkeydata:/data

  mailcatcher:
    image: schickling/mailcatcher
    ports:
      - 1080:1080

  # -------------------------------------------------------------#

  app: &app
    image: todo-list-app
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - .:/app #map toàn bộ code hiện tại vào /app trong container
      - bundler:/app/.bundle #Tạo một volume tên bundler để lưu thư viện Ruby (bundle install).
      - node_modules:/app/node_modules #Tạo một volume tên node_modules để lưu thư viện Node.js (npm install).
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: todos_development
      DB_USERNAME: postgres
      DB_PASSWORD: ""
      REDIS_HOST: valkey
      SMTP_HOST: mailcatcher
    depends_on:
      - postgres
      - valkey
    tty: true # Bật terminal ảo cho container
    stdin_open: true # Cho phép nhập lệnh tương tác với terminal

  web:
    <<: *app
    command: bash -c "bundle install && rm -f tmp/pids/web.pid && bin/rails server -b 0.0.0.0 -p 4000"
    environment:
      DB_HOST: postgres
      REDIS_HOST: valkey
      SMTP_HOST: mailcatcher
      PIDFILE: tmp/pids/web.pid
    ports:
      - 4000:4000

  sidekiq:
    <<: *app
COPY . .

# Step 3: Runtime base (New image) (Create env clearly)
FROM docker.io/library/ruby:$RUBY_VERSION-bookworm AS runtime-base

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      postgresql-client \
      cron && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set environment: os, ruby, application
ENV TZ="Asia/Ho_Chi_Minh" \
    RUBY_YJIT_ENABLE=1 \
    RUBYOPT="-W:deprecated --yjit-exec-mem-size=128" \
    BUNDLE_PATH=".bundle" \
    PATH=/usr/local/node/bin:$PATH

# Copy Node.js và yarn từ build stage
COPY --from=build /usr/local/node /usr/local/node

# Copy toàn bộ app đã build từ build stage sang runtime stage
# Bao gồm: Ruby gems, Node modules, source code, compiled assets
COPY --from=build /app /app

# Copy compiled frontend assets để serve static files (CSS, JS, images)
COPY --from=build /app/public/vite ./app/public/vite

EXPOSE 4000

FROM node:20.19.2-alpine AS frontend

WORKDIR /app

COPY package.json yarn.lock .yarnrc.yml ./

RUN yarn install

COPY app/frontend ./app/frontend
COPY vite.config.mts ./
COPY config/vite.json ./config/

RUN yarn build

FROM ruby:3.3.0-alpine AS rails

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    tzdata \
    nodejs \
    yarn

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

COPY . .

# Copy built frontend assets from frontend stage
COPY --from=frontend /app/public/vite ./public/vite

EXPOSE 3000

# Start Rails server
CMD ["sh", "-c", "bundle exec bin/vite dev & bundle exec rails server -b 0.0.0.0 -p 3000"]

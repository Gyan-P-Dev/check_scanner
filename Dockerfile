# syntax = docker/dockerfile:1

# Base Ruby image
ARG RUBY_VERSION=3.3.1
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Set working directory
WORKDIR /rails

# Set production environment variables
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Build stage to install dependencies and gems
FROM base as build

# Install build tools and dependencies for PostgreSQL & OCR
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    git \
    libvips \
    pkg-config \
    tesseract-ocr \
    tesseract-ocr-eng \
    libtesseract-dev \
    libleptonica-dev \
    imagemagick \
    libmagickwand-dev \
    poppler-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile assets and Bootsnap
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for the production image
FROM base

# Set environment variables
ENV SECRET_KEY_BASE=sdfdsdfdsdsfdfd

# Install runtime dependencies for PostgreSQL & OCR
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libpq5 \
    libpq-dev \
    nano \
    tesseract-ocr \
    tesseract-ocr-eng \
    libtesseract-dev \
    libleptonica-dev \
    imagemagick \
    poppler-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy built gems and application code from the build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create required directories
RUN mkdir -p /rails/log /rails/tmp

# Set permissions for the Rails user
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails /rails/log /rails/tmp /rails/storage

USER rails:rails

# Entrypoint to prepare the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose ports
EXPOSE 3000
EXPOSE 1234

# Start Rails server
CMD ["./bin/rails", "server"]

FROM elixir:1.18-otp-27-alpine

# Install build dependencies
RUN apk add --no-cache build-base git nodejs npm inotify-tools

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get

# Copy all application files
COPY . .

# Compile dependencies
RUN mix deps.compile

# Expose port
EXPOSE 4000

# Set environment
ENV MIX_ENV=dev

# Start the Phoenix server
CMD ["mix", "phx.server"]

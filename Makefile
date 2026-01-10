.PHONY: dev setup_db setup test console

# Start Phoenix server in development mode
dev:
	mix phx.server

# Reset database and run seeds (drop, create, migrate, seeds)
setup_db:
	mix ecto.drop
	mix ecto.create
	mix ecto.migrate
	mix run priv/repo/seeds.exs

# Full project setup: deps, database, migrations, seeds, assets
setup:
	mix setup

# Run tests
test:
	mix test

# Start interactive Elixir shell with Phoenix
console:
	iex -S mix phx.server

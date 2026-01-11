defmodule PuenteApp.Repo do
  use Ecto.Repo,
    otp_app: :puente_app,
    adapter: Ecto.Adapters.Postgres
end

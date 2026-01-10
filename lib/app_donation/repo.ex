defmodule AppDonation.Repo do
  use Ecto.Repo,
    otp_app: :app_donation,
    adapter: Ecto.Adapters.Postgres
end

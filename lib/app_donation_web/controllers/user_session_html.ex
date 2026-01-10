defmodule AppDonationWeb.UserSessionHTML do
  use AppDonationWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:app_donation, AppDonation.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end

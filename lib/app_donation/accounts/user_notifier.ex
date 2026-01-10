defmodule AppDonation.Accounts.UserNotifier do
  import Swoosh.Email

  alias AppDonation.Mailer

  # Default sender configuration
  @default_from_name "AppDonation"
  @default_from_email "noreply@appdonation.com"

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    {from_name, from_email} = get_sender()

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp get_sender do
    from_name = Application.get_env(:app_donation, :mailer_from_name, @default_from_name)
    from_email = Application.get_env(:app_donation, :mailer_from_email, @default_from_email)
    {from_name, from_email}
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver email confirmation instructions.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirma tu cuenta", """

    ==============================

    Hola #{user.first_name || user.email},

    Podes confirmar tu cuenta haciendo click en el siguiente link:

    #{url}

    Este link expira en 48 horas.

    Si no creaste una cuenta, ignora este email.

    ==============================
    """)
  end
end

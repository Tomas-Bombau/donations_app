defmodule AppDonation.Accounts.UserNotifier do
  import Swoosh.Email

  alias AppDonation.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"AppDonation", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
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

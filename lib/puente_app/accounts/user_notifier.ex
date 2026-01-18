defmodule PuenteApp.Accounts.UserNotifier do
  import Swoosh.Email

  alias PuenteApp.Mailer

  # Default sender configuration
  @default_from_name "PuenteApp"
  @default_from_email "noreply@appdonation.com"

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, text_body, html_body) do
    {from_name, from_email} = get_sender()

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(text_body)
      |> html_body(html_body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp get_sender do
    from_name = Application.get_env(:puente_app, :mailer_from_name, @default_from_name)
    from_email = Application.get_env(:puente_app, :mailer_from_email, @default_from_email)
    {from_name, from_email}
  end

  defp base_layout(content) do
    """
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5;">
      <table role="presentation" style="width: 100%; border-collapse: collapse;">
        <tr>
          <td align="center" style="padding: 40px 20px;">
            <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
              <!-- Header -->
              <tr>
                <td align="center" style="padding: 30px 40px; background-color: #7c3aed; border-radius: 12px 12px 0 0;">
                  <h1 style="margin: 0; font-size: 28px; font-weight: 700; color: #ffffff;">PuenteApp</h1>
                </td>
              </tr>
              <!-- Content -->
              <tr>
                <td style="padding: 40px; background-color: #ffffff;">
                  #{content}
                </td>
              </tr>
              <!-- Footer -->
              <tr>
                <td align="center" style="padding: 30px 40px; background-color: #f9fafb; border-radius: 0 0 12px 12px;">
                  <p style="margin: 0; font-size: 14px; color: #6b7280;">
                    Este email fue enviado por PuenteApp.<br>
                    Si no solicitaste este email, podés ignorarlo.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    text_body = """
    Hola #{user.email},

    Recibimos una solicitud para cambiar tu email.

    Podés actualizar tu email visitando el siguiente link:

    #{url}

    Si no solicitaste este cambio, ignorá este email.

    - El equipo de PuenteApp
    """

    html_content = """
    <h2 style="margin: 0 0 20px 0; font-size: 24px; font-weight: 600; color: #111827;">
      Actualizar email
    </h2>
    <p style="margin: 0 0 15px 0; font-size: 16px; line-height: 1.6; color: #374151;">
      Hola <strong>#{user.email}</strong>,
    </p>
    <p style="margin: 0 0 25px 0; font-size: 16px; line-height: 1.6; color: #374151;">
      Recibimos una solicitud para cambiar tu dirección de email. Hacé click en el botón de abajo para continuar.
    </p>
    <table role="presentation" style="width: 100%; border-collapse: collapse;">
      <tr>
        <td align="center" style="padding: 10px 0 30px 0;">
          <a href="#{url}" style="display: inline-block; padding: 14px 32px; background-color: #7c3aed; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
            Actualizar email
          </a>
        </td>
      </tr>
    </table>
    <p style="margin: 0 0 10px 0; font-size: 14px; color: #6b7280;">
      O copiá y pegá este link en tu navegador:
    </p>
    <p style="margin: 0; font-size: 14px; color: #7c3aed; word-break: break-all;">
      #{url}
    </p>
    """

    deliver(user.email, "Actualizá tu email", text_body, base_layout(html_content))
  end

  @doc """
  Deliver email confirmation instructions.
  """
  def deliver_confirmation_instructions(user, url) do
    name = user.first_name || user.email

    text_body = """
    Hola #{name},

    ¡Gracias por registrarte en PuenteApp!

    Podés confirmar tu cuenta visitando el siguiente link:

    #{url}

    Este link expira en 48 horas.

    Si no creaste una cuenta, ignorá este email.

    - El equipo de PuenteApp
    """

    html_content = """
    <h2 style="margin: 0 0 20px 0; font-size: 24px; font-weight: 600; color: #111827;">
      ¡Bienvenido a PuenteApp!
    </h2>
    <p style="margin: 0 0 15px 0; font-size: 16px; line-height: 1.6; color: #374151;">
      Hola <strong>#{name}</strong>,
    </p>
    <p style="margin: 0 0 25px 0; font-size: 16px; line-height: 1.6; color: #374151;">
      Gracias por registrarte. Solo falta un paso: confirmá tu cuenta haciendo click en el botón de abajo.
    </p>
    <table role="presentation" style="width: 100%; border-collapse: collapse;">
      <tr>
        <td align="center" style="padding: 10px 0 30px 0;">
          <a href="#{url}" style="display: inline-block; padding: 14px 32px; background-color: #7c3aed; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
            Confirmar mi cuenta
          </a>
        </td>
      </tr>
    </table>
    <p style="margin: 0 0 10px 0; font-size: 14px; color: #6b7280;">
      O copiá y pegá este link en tu navegador:
    </p>
    <p style="margin: 0 0 20px 0; font-size: 14px; color: #7c3aed; word-break: break-all;">
      #{url}
    </p>
    <div style="padding: 15px; background-color: #fef3c7; border-radius: 8px; border-left: 4px solid #f59e0b;">
      <p style="margin: 0; font-size: 14px; color: #92400e;">
        <strong>Importante:</strong> Este link expira en 48 horas.
      </p>
    </div>
    """

    deliver(user.email, "Confirmá tu cuenta en PuenteApp", text_body, base_layout(html_content))
  end
end

defmodule PuenteAppWeb.Helpers.FormatHelpers do
  @moduledoc """
  Helper functions for formatting values in LiveViews and templates.
  """

  @doc """
  Formats a Decimal amount as currency with $ prefix.
  """
  def format_currency(amount) do
    amount
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> then(&"$#{&1}")
  end

  @doc """
  Formats a date as dd/mm/yyyy.
  """
  def format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  @doc """
  Formats a datetime as dd/mm/yyyy.
  """
  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end

  @doc """
  Returns the badge CSS class for a request status (organization view).
  """
  def status_badge(status) do
    case status do
      :draft -> "badge-warning"
      :active -> "badge-success"
      :completed -> "badge-error"
      :closed -> "badge-info"
    end
  end

  @doc """
  Returns the human-readable label for a request status (organization view).
  """
  def status_label(status) do
    case status do
      :draft -> "Borrador"
      :active -> "Activo"
      :completed -> "Finalizado"
      :closed -> "Cerrado"
    end
  end

  @doc """
  Returns the badge CSS class for a request status (donor view).
  """
  def request_status_badge(status) do
    case status do
      :draft -> "badge-ghost"
      :active -> "badge-warning"
      :completed -> "badge-error"
      :closed -> "badge-success"
    end
  end

  @doc """
  Returns the human-readable label for a request status (donor view).
  """
  def request_status_label(status) do
    case status do
      :draft -> "Borrador"
      :active -> "En curso"
      :completed -> "Pendiente de rendicion"
      :closed -> "Rendicion disponible"
    end
  end

  @doc """
  Converts upload error atoms to human-readable strings.
  """
  def error_to_string(:too_large), do: "El archivo es muy grande (max 5MB)"
  def error_to_string(:not_accepted), do: "Tipo de archivo no permitido. Solo JPG, PNG o WebP"
  def error_to_string(:too_many_files), do: "Solo se permite un archivo"
  def error_to_string(_), do: "Error al subir el archivo"
end

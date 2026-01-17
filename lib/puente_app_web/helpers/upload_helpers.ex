defmodule PuenteAppWeb.Helpers.UploadHelpers do
  @moduledoc """
  Helpers for secure file upload handling.
  Validates file content via magic bytes and generates secure filenames.
  """

  @doc """
  Validates file content by checking magic bytes.
  Returns {:ok, detected_type} or {:error, reason}.

  Supported types: :jpeg, :png, :webp
  """
  def validate_magic_bytes(path) do
    case File.read(path) do
      {:ok, content} -> validate_content(content)
      {:error, _} -> {:error, :file_read_error}
    end
  end

  # JPEG: starts with FF D8 FF
  defp validate_content(<<0xFF, 0xD8, 0xFF, _rest::binary>>), do: {:ok, :jpeg}

  # PNG: starts with 89 50 4E 47 0D 0A 1A 0A
  defp validate_content(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>>),
    do: {:ok, :png}

  # WebP: starts with RIFF....WEBP
  defp validate_content(<<"RIFF", _size::binary-size(4), "WEBP", _rest::binary>>), do: {:ok, :webp}

  defp validate_content(_), do: {:error, :invalid_file_type}

  @doc """
  Generates a secure random filename with proper extension based on detected type.
  """
  def generate_secure_filename(detected_type) do
    uuid = Ecto.UUID.generate()
    extension = type_to_extension(detected_type)
    "#{uuid}#{extension}"
  end

  defp type_to_extension(:jpeg), do: ".jpg"
  defp type_to_extension(:png), do: ".png"
  defp type_to_extension(:webp), do: ".webp"

  @doc """
  Validates that the client-provided extension matches the detected file type.
  Prevents attacks where malicious files are uploaded with wrong extensions.
  """
  def extension_matches_type?(client_name, detected_type) do
    ext = client_name |> Path.extname() |> String.downcase()

    case {ext, detected_type} do
      {ext, :jpeg} when ext in [".jpg", ".jpeg"] -> true
      {".png", :png} -> true
      {".webp", :webp} -> true
      _ -> false
    end
  end
end

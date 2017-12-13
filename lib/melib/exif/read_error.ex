defmodule Melib.Exif.ReadError do
  defexception [:type, :file, :message]

  def exception(type: type, file: file) do
    msg = case file do
      nil -> "Error reading EXIF data from buffer"
      _   -> "Error reading EXIF data from file [#{file}]"
    end

    %Melib.Exif.ReadError{type: type, file: file, message: msg}
  end
end

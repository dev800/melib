defmodule Melib.QRCode do
  defdelegate to_png(text, opts \\ []), to: QRCode
  defdelegate to_png_file(text, file_path, opts \\ []), to: QRCode
end

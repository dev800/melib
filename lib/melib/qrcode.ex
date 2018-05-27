defmodule Melib.QRCode do

  defdelegate to_png(text), to: QRCode
  defdelegate to_png_file(text, file_path), to: QRCode

end

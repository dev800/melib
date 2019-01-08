defmodule Melib.HEIC do
  def to_jpeg(%Melib.Image{mime_type: "image/heic"} = image) do
    Melib.Convert.convert(image, format: "jpeg")
  end

  def to_jpeg(file), do: file
end

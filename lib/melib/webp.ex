defmodule Melib.Webp do
  def to_jpeg(%Melib.Image{mime_type: "image/webp"} = image) do
    Melib.Convert.convert(image, format: "jpeg")
  end

  def to_jpeg(file), do: file
end

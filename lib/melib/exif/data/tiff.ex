defmodule Melib.Exif.Data.Tiff do
  @fields [
    :make,
    :model,
    :modify_date,
    :orientation,
    :resolution_units,
    :software,
    :x_resolution,
    :y_resolution
  ]

  def fields, do: @fields

  defstruct @fields

  def from_map(data) do
    struct(__MODULE__, data)
  end

  def to_map(data) do
    data |> Map.take(@fields)
  end

  defimpl String.Chars, for: Melib.Exif.Data.Tiff do
    def to_string(data), do: "Image Tiff: {make: #{data.make}, model: #{data.model}}"
  end
end

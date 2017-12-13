defmodule Melib.Exif.Data.Thumbnail do
  @fields [
    :thumbnail_offset,
    :thumbnail_size
  ]

  def fields, do: @fields

  defstruct @fields

  def from_map(data) do
    struct(__MODULE__, data)
  end

  def to_map(data) do
    data |> Map.take(@fields)
  end

  def to_image(_, %{thumbnail_offset: offset, thumbnail_size: size}) when is_nil(offset) or is_nil(size), do: nil
  def to_image(file, %{thumbnail_offset: offset, thumbnail_size: size}) when is_binary(file) do
    [name, dot, ext] = String.split(file, ~r/(?=.{3,4}\z)/)
    File.open!(file, [:read], fn(from) ->
      File.open!("#{name}-thumb#{dot}#{ext}", [:write], fn(to) ->
        IO.binread(from, offset)
        IO.binwrite to, (IO.binread(from, size))
      end)
    end)
  end

  defimpl String.Chars, for: Melib.Exif.Data.Thumbnail do
    def to_string(data), do: "Image Thumbnail of size #{data.thumbnail_size}"
  end
end

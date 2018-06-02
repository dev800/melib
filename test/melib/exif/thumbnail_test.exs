defmodule Melib.Exif.ThumbnailTest do
  use ExUnit.Case

  @filename Path.join(__DIR__, "../../fixtures/img/for_exif/cactus.jpg")
  @thumbname Path.join(__DIR__, "../../fixtures/img/for_exif/cactus-thumb.jpg")

  import Melib.Exif

  test "thumbnail fields are recognized properly" do
    metadata = exif_from_jpeg_file!(@filename)

    Melib.Exif.Data.Thumbnail.to_image(@filename, metadata.thumbnail)
    assert File.exists?(@thumbname)
    File.rm!(@thumbname)

    assert %Melib.Exif.Data.Thumbnail{
             thumbnail_offset: 631,
             thumbnail_size: 19837
           } = metadata.thumbnail |> Melib.Exif.Data.Thumbnail.from_map()
  end
end

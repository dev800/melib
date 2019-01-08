defmodule Melib.HEICTest do
  use ExUnit.Case
  import Melib.HEIC

  @heic_file Path.join(__DIR__, "../fixtures/img/IMG_5364")

  test "read ok" do
    image = Melib.Identify.identify(@heic_file)
    jpg_image = HEIC.to_jpeg(image)

    assert %Melib.Image{
             format: "jpg",
             mime_type: "image/jpeg",
             height: 4032,
             width: 3024,
             size: 3_311_552
           } = jpg_image
  end
end

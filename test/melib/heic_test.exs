defmodule Melib.HeicTest do
  use ExUnit.Case
  alias Melib.Heic

  @heic_file Path.join(__DIR__, "../fixtures/img/heic")

  test "read ok" do
    image = Melib.Identify.identify(@heic_file)
    jpg_image = Heic.to_jpeg(image)

    assert %Melib.Image{
             format: "jpeg",
             mime_type: "image/jpeg",
             height: 4032,
             width: 3024,
             size: 3_311_552
           } = jpg_image
  end
end

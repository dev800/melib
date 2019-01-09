defmodule Melib.WebpTest do
  use ExUnit.Case
  alias Melib.Webp

  @heic_file Path.join(__DIR__, "../fixtures/img/webp")

  test "read ok" do
    image = Melib.Identify.identify(@heic_file)
    jpg_image = Webp.to_jpeg(image)

    assert %Melib.Image{
             format: "jpeg",
             mime_type: "image/jpeg",
             height: 380,
             width: 380,
             size: 41733
           } = jpg_image
  end
end

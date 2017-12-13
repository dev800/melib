defmodule Melib.IdentifyTest do

  alias Melib.Mogrify
  alias Melib.Image
  alias Melib.Identify

  use ExUnit.Case, async: true

  @fixture Path.join(__DIR__, "../fixtures/img/bender.jpg")

  describe "identify" do
    test "mime_type" do
      mime_type = 
        @fixture
        |> Mogrify.open
        |> Identify.mime_type

      assert mime_type == "image/jpeg"
    end

    test "identify" do
      image = Identify.identify(@fixture)

      assert %Melib.Image{
        animated: false,
        dirty: %{},
        ext: ".jpg",
        file: nil,
        filename: "bender.jpg",
        format: "jpeg",
        frame_count: 1,
        height: 292,
        md5: nil,
        mime_type: "image/jpeg",
        operations: [],
        path: _path,
        postfix: ".jpeg",
        sha256: nil,
        sha512: nil,
        size: 23465,
        width: 300
      } = image

      image = image |> Identify.put_md5
      image = image |> Identify.put_sha512
      image = image |> Identify.put_sha256

      assert image.md5 == "004c54015d933acf76fe2a541b7585be"
      assert image.sha256 == "3ddcfb07a3ebca9d54a89b0e25783b03e17a0324d8e508089c438ab692dafdb0"
      assert image.sha512 == "1532b9762728cdf65d04892e80196e6d65b1392806be632006b7f9bd79a0e3e25e6dd256194fcc554892b1e8a4d7da551ffa02d177134195954900e69d850e76"
    end
  end

end

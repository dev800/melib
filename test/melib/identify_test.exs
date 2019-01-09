defmodule Melib.IdentifyTest do
  alias Melib.Mogrify
  alias Melib.Identify

  use ExUnit.Case, async: true

  # 逆时针旋转90度
  @rotate_jpg_1 Path.join(__DIR__, "../fixtures/img/for_exif/Rotate_1.jpg")
  # 正常
  @rotate_jpg_2 Path.join(__DIR__, "../fixtures/img/for_exif/Rotate_2.jpg")
  # 顺时针旋转90度
  @rotate_jpg_3 Path.join(__DIR__, "../fixtures/img/for_exif/Rotate_3.jpg")
  # 旋转180度
  @rotate_jpg_4 Path.join(__DIR__, "../fixtures/img/for_exif/Rotate_4.jpg")
  @fixture Path.join(__DIR__, "../fixtures/img/bender.jpg")
  @gif_fixture Path.join(__DIR__, "../fixtures/img/bender_anim.gif")
  @fixture_from_iphone Path.join(__DIR__, "../fixtures/img/from_iphone.jpg")
  @fixture_text Path.join(__DIR__, "../fixtures/img/text.txt")
  @fixture_incorrect_sbit Path.join(__DIR__, "../fixtures/img/Incorrect_sBIT.jpg")

  describe "identify" do
    test "rotate_jpg_1" do
      media = @rotate_jpg_1 |> Identify.identify()

      assert media.height == 4032
      assert media.width == 3024
    end

    test "rotate_jpg_2" do
      media = @rotate_jpg_2 |> Identify.identify()

      assert media.width == 4032
      assert media.height == 3024
    end

    test "rotate_jpg_3" do
      media = @rotate_jpg_3 |> Identify.identify()

      assert media.height == 4032
      assert media.width == 3024
    end

    test "rotate_jpg_4" do
      media = @rotate_jpg_4 |> Identify.identify()

      assert media.width == 4032
      assert media.height == 3024
    end

    test "mime_type" do
      mime_type =
        @fixture
        |> Mogrify.open()
        |> Identify.mime_type()

      assert mime_type == "image/jpeg"
    end

    test "exif" do
      image =
        @fixture_from_iphone
        |> Identify.identify()
        |> Identify.put_exif()

      assert image.exif == %{
               :exif => %{
                 aperture_value: 2.275,
                 brightness_value: 2.447,
                 color_space: "sRGB",
                 component_configuration: "Y,Cb,Cr,-",
                 datetime_digitized: "2017:12:13 18:36:56",
                 datetime_original: "2017:12:13 18:36:56",
                 exif_image_height: 3024,
                 exif_image_width: 4032,
                 exif_version: "2.21",
                 exposure_bias_value: 0,
                 exposure_mode: "Auto",
                 exposure_program: "Program AE",
                 exposure_time: "1/33",
                 f_number: 2.2,
                 flash: "Auto, Did not fire",
                 flash_pix_version: "1.00",
                 focal_length: 4.15,
                 focal_length_in_35mm_film: 29,
                 iso_speed_ratings: 125,
                 lens_info: [4.15, 4.15, 2.2, 2.2],
                 lens_make: "Apple",
                 lens_model: "iPhone SE back camera 4.15mm f/2.2",
                 maker_note: nil,
                 metering_mode: "Multi-segment",
                 scene_capture_type: "Standard",
                 scene_type: "Directly photographed",
                 sensing_method: "One-chip color area",
                 shutter_speed_value: 5.059,
                 subject_area: nil,
                 subsec_time_digitized: "036",
                 subsec_time_orginal: "036",
                 white_balance: "Auto"
               },
               :gps => %{
                 gps_altitude: 24.449,
                 gps_altitude_ref: 0,
                 gps_date_stamp: "2017:12:13",
                 gps_dest_bearing: 261.709,
                 gps_dest_bearing_ref: "T",
                 gps_h_positioning_errorl: 65,
                 gps_img_direction: 261.709,
                 gps_img_direction_ref: "T",
                 gps_latitude: [22, 32, 44.5],
                 gps_latitude_ref: "N",
                 gps_longitude: [113, 56, 39.42],
                 gps_longitude_ref: "E",
                 gps_speed: 0,
                 gps_speed_ref: "K",
                 gps_time_stamp: [10, 36, 52.19]
               },
               :tiff => %{
                 :make => "Apple",
                 :model => "iPhone SE",
                 :modify_date => "\"2017:12:13 18:36:56\"",
                 :orientation => "Rotate 90 CW",
                 :resolution_units => "Pixels/in",
                 :software => "11.2",
                 :x_resolution => 72,
                 :y_resolution => 72
               },
               :"tiff tag(0x213)" => "1"
             }
    end

    test "identify with text" do
      attachment = Identify.identify(@fixture_text)

      assert %Melib.Attachment{
               dirty: %{},
               ext: ".txt",
               file: nil,
               filename: "text.txt",
               md5: nil,
               mime_type: "text/plain",
               operations: [],
               path: _path,
               postfix: ".txt",
               format: "txt",
               sha256: nil,
               sha512: nil,
               size: 12
             } = attachment
    end

    test "identify" do
      image =
        @fixture
        |> Identify.identify()
        |> Identify.put_width_and_height()

      assert %Melib.Image{
               animated: false,
               dirty: %{},
               exif: %{},
               ext: ".jpg",
               file: _file,
               filename: "bender.jpg",
               format: "jpeg",
               frame_count: 1,
               height: 292,
               md5: nil,
               md5_hash: nil,
               mime_type: "image/jpeg",
               operations: [],
               postfix: ".jpeg",
               sha256: nil,
               sha256_hash: nil,
               sha512: nil,
               sha512_hash: nil,
               size: 23465,
               width: 300
             } = image

      image = image |> Identify.put_md5()
      image = image |> Identify.put_sha512()
      image = image |> Identify.put_sha256()

      assert image.md5 == "004c54015d933acf76fe2a541b7585be"
      assert image.sha256 == "3ddcfb07a3ebca9d54a89b0e25783b03e17a0324d8e508089c438ab692dafdb0"

      assert image.sha512 ==
               "1532b9762728cdf65d04892e80196e6d65b1392806be632006b7f9bd79a0e3e25e6dd256194fcc554892b1e8a4d7da551ffa02d177134195954900e69d850e76"
    end

    test "identify gif" do
      image =
        @gif_fixture
        |> Identify.identify()
        |> Identify.put_width_and_height()

      assert %Melib.Image{
               animated: true,
               dirty: %{},
               exif: %{},
               ext: ".gif",
               file: nil,
               filename: "bender_anim.gif",
               format: "gif",
               frame_count: 2,
               height: 292,
               md5: nil,
               md5_hash: nil,
               mime_type: "image/gif",
               operations: [],
               path: _path,
               postfix: ".gif",
               sha256: nil,
               sha256_hash: nil,
               sha512: nil,
               sha512_hash: nil,
               size: 76607,
               width: 300
             } = image
    end

    test "identify Incorrect_sBIT" do
      image =
        @fixture_incorrect_sbit
        |> Identify.identify()
        |> Identify.put_width_and_height()

      assert %Melib.Image{
               animated: false,
               dirty: %{},
               exif: %{},
               ext: ".jpg",
               file: nil,
               filename: "Incorrect_sBIT.jpg",
               format: "png",
               frame_count: 1,
               height: 645,
               md5: nil,
               md5_hash: nil,
               mime_type: "image/png",
               operations: [],
               path: _path,
               postfix: ".png",
               sha256: nil,
               sha256_hash: nil,
               sha512: nil,
               sha512_hash: nil,
               size: 334_064,
               width: 452
             } = image

      image =
        image
        |> Identify.put_md5()
        |> Identify.put_sha512()
        |> Identify.put_sha256()

      assert image.md5 == "33a2c0da51b45c9327c39f75c0523b5a"
      assert image.sha256 == "b072a5d337ce4563c930f413418ee6ec90aefadf039ac61728b2e1b8d7a2f42b"

      assert image.sha512 ==
               "454ab4412cb4b7bbd7cf23c785b1a725373aa2800f9f4e69486b8486925a6721b3b8d1eaae8bec5f0c004858955d515939d9db67f5070c8bf4a56e574cf2e811"
    end
  end
end

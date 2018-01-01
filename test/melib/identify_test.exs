defmodule Melib.IdentifyTest do

  alias Melib.Mogrify
  alias Melib.Identify

  use ExUnit.Case, async: true

  @fixture Path.join(__DIR__, "../fixtures/img/bender.jpg")
  @fixture_from_iphone Path.join(__DIR__, "../fixtures/img/from_iphone.jpg")
  @fixture_text Path.join(__DIR__, "../fixtures/img/text.txt")

  describe "identify" do
    test "mime_type" do
      mime_type = 
        @fixture
        |> Mogrify.open
        |> Identify.mime_type

      assert mime_type == "image/jpeg"
    end

    test "exif" do
      image =
        @fixture_from_iphone
        |> Identify.identify
        |> Identify.put_exif

      assert image.exif == %{
        :exif => %{aperture_value: 2.275, brightness_value: 2.447,
          color_space: "sRGB", component_configuration: "Y,Cb,Cr,-",
          datetime_digitized: "2017:12:13 18:36:56",
          datetime_original: "2017:12:13 18:36:56", exif_image_height: 3024,
          exif_image_width: 4032, exif_version: "2.21", exposure_bias_value: 0,
          exposure_mode: "Auto", exposure_program: "Program AE",
          exposure_time: "1/33", f_number: 2.2, flash: "Auto, Did not fire",
          flash_pix_version: "1.00", focal_length: 4.15,
          focal_length_in_35mm_film: 29, iso_speed_ratings: 125,
          lens_info: [4.15, 4.15, 2.2, 2.2], lens_make: "Apple",
          lens_model: "iPhone SE back camera 4.15mm f/2.2", maker_note: nil,
          metering_mode: "Multi-segment", scene_capture_type: "Standard",
          scene_type: "Directly photographed", sensing_method: "One-chip color area",
          shutter_speed_value: 5.059, subject_area: nil, subsec_time_digitized: "036",
          subsec_time_orginal: "036", white_balance: "Auto"
        },
        :gps => %{
          gps_altitude: 24.449, gps_altitude_ref: 0,
          gps_date_stamp: "2017:12:13", gps_dest_bearing: 261.709,
          gps_dest_bearing_ref: "T", gps_h_positioning_errorl: 65,
          gps_img_direction: 261.709, gps_img_direction_ref: "T",
          gps_latitude: [22, 32, 44.5], gps_latitude_ref: "N",
          gps_longitude: [113, 56, 39.42], gps_longitude_ref: "E", gps_speed: 0,
          gps_speed_ref: "K", gps_time_stamp: [10, 36, 52.19]
        },
        :tiff => %{
          :make => "Apple",
          :model => "iPhone SE",
          :modify_date => "\"2017:12:13 18:36:56\"",
          :orientation => "Rotate 90 CW",
          :resolution_units => "Pixels/in",
          :software => "11.2",
          :x_resolution => 72,
          :y_resolution => 72,
        },
        "tiff tag(0x213)" => "1"
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
      image = Identify.identify(@fixture)

      assert %Melib.Image{
        animated: false,
        dirty: %{},
        ext: ".jpg",
        file: nil,
        filename: "bender.jpg",
        frame_count: 1,
        height: 292,
        md5: nil,
        mime_type: "image/jpeg",
        operations: [],
        path: _path,
        postfix: ".jpg",
        format: "jpg",
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

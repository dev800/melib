defmodule Melib.MogrifyTest do
  import Melib.Mogrify

  alias Melib.Mogrify
  alias Melib.Image

  use ExUnit.Case, async: true

  @gif_fixture_src Path.join(__DIR__, "../fixtures/img/gif_src")
  @gif_fixture Path.join(__DIR__, "../fixtures/img/bender_anim.gif")
  @fixture Path.join(__DIR__, "../fixtures/img/bender.jpg")
  @fixture_with_space Path.join(__DIR__, "../fixtures/img/image with space in name/ben der.jpg")
  @fixture_animated Path.join(__DIR__, "../fixtures/img/bender_anim.gif")
  @fixture_rgbw Path.join(__DIR__, "../fixtures/img/rgbw.png")
  @temp_test_directory Path.join(__DIR__, "../tmp/mogrify test folder") |> Path.expand()
  @temp_image_with_space Path.join(@temp_test_directory, "1 1.jpg")

  @fixture_incorrect_sbit Path.join(__DIR__, "../fixtures/img/Incorrect_sBIT.jpg")

  @fixture_meijing Path.join(__DIR__, "../fixtures/img/meijing.png")
  @fixture_watermark Path.join(__DIR__, "../fixtures/img/watermark.png")
  @fixture_tmp_folder Path.join(__DIR__, "../tmp/mogrify") |> Path.expand()

  describe "Incorrect_sBIT Testing" do
    setup do
      File.mkdir_p!(@fixture_tmp_folder)
      %{}
    end

    test "watermark and resize and text" do
      @fixture_incorrect_sbit
      |> Mogrify.open()
      |> Mogrify.quality(70)
      |> Mogrify.gravity("Center")
      |> Mogrify.verbose()
      |> Mogrify.resize("520>")
      # |> Mogrify.resize_to_fill("420x420")
      |> Mogrify.watermark(@fixture_watermark, gravity: "NorthEast")
      |> Mogrify.draw_text(text: "你好世界@hello world 20181126", gravity: "Center", fill: "red", x: 4, y: 4, font: :default)
      |> Mogrify.draw_text(text: "你好世界@ABC", fill: "green", gravity: "SouthEast", x: 4, y: 4, font: :default)
      |> Mogrify.create(
        path: @fixture_tmp_folder <> "/Incorrect_sBIT.with_watermark_text_520.jpg"
      )
    end
  end

  describe "Basic Testing For" do
    setup do
      File.mkdir_p!(@fixture_tmp_folder)
      %{}
    end

    test "gif create from sources" do
      image =
        Mogrify.create_gif_from(
          [
            @gif_fixture_src |> Path.join("img_1.png"),
            @gif_fixture_src |> Path.join("img_2.png"),
            @gif_fixture_src |> Path.join("img_3.png"),
            @gif_fixture_src |> Path.join("img_4.png")
          ],
          path: @fixture_tmp_folder <> "/gif_create2.gif"
        )

      assert Map.take(image, [:width, :height, :frame_count, :mime_type]) == %{
               frame_count: 4,
               height: 46,
               mime_type: "image/gif",
               width: 70
             }
    end

    test "gif resize" do
      @fixture_animated
      |> Mogrify.open()
      |> Mogrify.resize("180>")
      |> Mogrify.create(path: @fixture_tmp_folder <> "/gif_180.gif")
    end

    test "gif resize and thumbnail" do
      @fixture_animated
      |> Mogrify.open()
      |> Mogrify.resize("180>")
      |> Mogrify.gif_thumbnail()
      |> Mogrify.create(path: @fixture_tmp_folder <> "/gif_180.jpg")
    end

    test "gif watermark skip" do
      @fixture_animated
      |> Mogrify.open()
      |> Mogrify.resize("180>")
      |> Mogrify.watermark(@fixture_watermark, gravity: "NorthEast", gif_skip: true)
      |> Mogrify.create(path: @fixture_tmp_folder <> "/gif_180_skip_watermark.gif")
    end

    test "gif watermark skip when size to small" do
      @fixture_animated
      |> Mogrify.open()
      |> Mogrify.resize("180>")
      |> Mogrify.watermark(
        @fixture_watermark,
        gravity: "NorthEast",
        gif_skip: true,
        min_width: 500,
        min_height: 500
      )
      |> Mogrify.create(
        path: @fixture_tmp_folder <> "/gif_180_skip_watermark_when_size_small.gif"
      )
    end

    test "resize" do
      @fixture_meijing
      |> Mogrify.open()
      |> Mogrify.resize("580>")
      |> Mogrify.create(path: @fixture_tmp_folder <> "/meijing_580.jpg")
    end

    test "draw text" do
      @fixture_meijing
      |> Mogrify.open()
      |> Mogrify.draw_text(text: "你好，图片，美景2017-12-13", fill: "red", x: 4, y: 4)
      |> Mogrify.create(path: @fixture_tmp_folder <> "/meijing_with_text.jpg")
    end

    test "draw text and resize" do
      @fixture_meijing
      |> Mogrify.open()
      |> Mogrify.resize("520>")
      |> Mogrify.draw_text(text: "你好，图片，美景2017-12-13", fill: "red", x: 4, y: 4)
      |> Mogrify.create(path: @fixture_tmp_folder <> "/meijing_with_text_520.jpg")
    end

    test "watermark" do
      @fixture_meijing
      |> Mogrify.open()
      |> Mogrify.watermark(@fixture_watermark, gravity: "NorthEast")
      |> Mogrify.create(path: @fixture_tmp_folder <> "/meijing_with_watermark.jpg")
    end

    test "watermark and resize" do
      @fixture_meijing
      |> Mogrify.open()
      |> Mogrify.resize("520>")
      |> Mogrify.watermark(@fixture_watermark, gravity: "NorthEast")
      |> Mogrify.create(path: @fixture_tmp_folder <> "/meijing_with_watermark_520.jpg")
    end

    test "watermark and resize and text" do
      @fixture_meijing
      |> Mogrify.open()
      |> Mogrify.verbose()
      |> Mogrify.resize("520>")
      |> Mogrify.watermark(@fixture_watermark, gravity: "NorthEast")
      |> Mogrify.draw_text(text: "你好，图片，美景2017-12-13", fill: "red", x: 4, y: 4)
      |> Mogrify.create(path: @fixture_tmp_folder <> "/meijing_with_watermark_text_520.jpg")
    end
  end

  describe "Origin Testing For" do
    test ".open" do
      %Image{path: path, ext: ".jpg"} = open(@fixture)
      assert Path.expand(@fixture) == path
    end

    test ".open when file name has spaces" do
      %Image{path: path, ext: ".jpg"} = open(@fixture_with_space)
      assert Path.expand(@fixture_with_space) == path
    end

    test ".open when file does not exist" do
      assert_raise File.Error, fn ->
        open("./test/fixtures/does_not_exist.jpg")
      end
    end

    test ".save" do
      path = Path.join(System.tmp_dir(), "1.jpg")
      image = open(@fixture) |> save(path: path)

      assert File.regular?(path)
      assert %Image{path: path} = image
      File.rm!(path)
    end

    test ".save when file name has spaces" do
      File.mkdir_p!(@temp_test_directory)

      image = open(@fixture) |> save(path: @temp_image_with_space)

      assert File.regular?(@temp_image_with_space)
      assert %Image{path: @temp_image_with_space} = image

      File.rm_rf!(@temp_test_directory)
    end

    test ".save in place" do
      # setup, make a copy
      path = Path.join(System.tmp_dir(), "1.jpg")
      open(@fixture) |> save(path: path)

      # test begins
      image = open(path) |> resize("600x600") |> save(in_place: true) |> verbose
      assert %Image{path: path, height: 584, width: 600} = image

      File.rm!(path)
    end

    test ".save in place when file name has spaces" do
      # setup, make a copy
      File.mkdir_p!(@temp_test_directory)
      open(@fixture) |> save(path: @temp_image_with_space)

      # test begins
      image = open(@temp_image_with_space) |> resize("600x600") |> save(in_place: true) |> verbose
      assert %Image{path: @temp_image_with_space, height: 584, width: 600} = image

      File.rm_rf!(@temp_test_directory)
    end

    test ".save :in_place ignores :path option" do
      # setup, make a copy
      path = Path.join(System.tmp_dir(), "1.jpg")
      open(@fixture) |> save(path: path)

      # test begins
      image =
        open(path) |> resize("600x600") |> save(in_place: true, path: "#{path}-ignore") |> verbose

      assert %Image{path: path, height: 584, width: 600} = image

      File.rm!(path)
    end

    test ".save :in_place ignores :path option when file name has spaces" do
      # setup, make a copy
      File.mkdir_p!(@temp_test_directory)
      open(@fixture) |> save(path: @temp_image_with_space)

      # test begins
      image =
        open(@temp_image_with_space)
        |> resize("600x600")
        |> save(in_place: true, path: "#{@temp_image_with_space}-ignore")
        |> verbose

      assert %Image{path: @temp_image_with_space, height: 584, width: 600} = image

      File.rm_rf!(@temp_test_directory)
    end

    test ".create" do
      path = Path.join(System.tmp_dir(), "1.jpg")
      image = %Image{path: path} |> canvas("white") |> create(path: path)

      assert File.exists?(path)
      assert %Image{path: path} = image

      File.rm!(path)
    end

    test ".create when file name has spaces" do
      File.mkdir_p!(@temp_test_directory)

      image =
        %Image{path: @temp_image_with_space}
        |> canvas("white")
        |> create(path: @temp_image_with_space)

      assert File.exists?(@temp_image_with_space)
      assert %Image{path: @temp_image_with_space} = image

      File.rm_rf!(@temp_test_directory)
    end

    test ".copy" do
      image = open(@fixture) |> copy
      tmp_dir = System.tmp_dir() |> Regex.escape()
      slash = if String.ends_with?(tmp_dir, "/"), do: "", else: "/"
      assert Regex.match?(~r(#{tmp_dir}melib-#{slash}\w+-bender\.jpeg), image.path)
    end

    test ".copy when file name has spaces" do
      image = open(@fixture_with_space) |> copy
      tmp_dir = System.tmp_dir() |> Regex.escape()
      slash = if String.ends_with?(tmp_dir, "/"), do: "", else: "/"
      assert Regex.match?(~r(#{tmp_dir}melib-#{slash}\w+-ben\sder\.jpeg), image.path)
    end

    test ".verbose" do
      image = open(@fixture)

      assert %Image{postfix: ".jpeg", ext: ".jpg", height: 292, width: 300, animated: false} =
               verbose(image)
    end

    test ".verbose when file name has spaces" do
      image = open(@fixture_with_space)

      assert %Image{postfix: ".jpeg", ext: ".jpg", height: 292, width: 300, animated: false} =
               verbose(image)
    end

    test ".verbose animated" do
      image = open(@fixture_animated)
      assert %Image{postfix: ".gif", ext: ".gif", animated: true} = verbose(image)
    end

    test ".verbose should not change file modification time" do
      %{mtime: old_time} = File.stat!(@fixture)

      :timer.sleep(1000)
      open(@fixture) |> verbose

      %{mtime: new_time} = File.stat!(@fixture)
      assert old_time == new_time
    end

    test ".verbose frame_count" do
      assert %Image{frame_count: 1} = open(@fixture) |> verbose
      assert %Image{frame_count: 2} = open(@fixture_animated) |> verbose
    end

    test ".format for gif save" do
      image = open(@gif_fixture) |> format("png") |> save |> verbose
      assert %Image{postfix: ".png", ext: ".png", height: 292, width: 300} = image
    end

    test ".format for gif create" do
      image = open(@gif_fixture) |> format("png") |> create |> verbose
      assert %Image{postfix: ".png", ext: ".png", height: 292, width: 300} = image
    end

    test ".format" do
      image = open(@fixture) |> format("png") |> save |> verbose
      assert %Image{postfix: ".png", ext: ".png", height: 292, width: 300} = image
    end

    test ".format updates format after save" do
      image = open(@fixture) |> format("png") |> save
      assert %Image{postfix: ".png", ext: ".png"} = image
    end

    test ".resize" do
      image = open(@fixture) |> resize("100x100") |> save |> verbose
      assert %Image{width: 100, height: 97} = image
    end

    test ".resize_to_fill" do
      image = open(@fixture) |> resize_to_fill("450x300") |> save |> verbose
      assert %Image{width: 450, height: 300} = image
    end

    test ".resize_to_limit" do
      image = open(@fixture) |> resize_to_limit("200x200") |> save |> verbose
      assert %Image{width: 200, height: 195} = image
    end

    test ".extent" do
      image = open(@fixture) |> extent("500x500") |> save |> verbose
      assert %Image{width: 500, height: 500} = image
    end

    test ".custom with plus-form of a command" do
      image_minus = open(@fixture) |> custom("raise", 50) |> save |> verbose
      image_plus = open(@fixture) |> custom("+raise", 50) |> save |> verbose
      %{size: size_minus} = File.stat!(image_minus.path)
      %{size: size_plus} = File.stat!(image_plus.path)
      assert size_minus != size_plus
    end

    test ".custom with explicit minus-form of a command" do
      image_implicit = open(@fixture) |> custom("raise", 50) |> save |> verbose
      image_explicit = open(@fixture) |> custom("-raise", 50) |> save |> verbose
      %{size: size_implicit} = File.stat!(image_implicit.path)
      %{size: size_explicit} = File.stat!(image_explicit.path)
      assert size_implicit == size_explicit
    end

    test ".histogram" do
      hist = open(@fixture_rgbw) |> histogram |> Enum.sort_by(fn %{"hex" => hex} -> hex end)

      expected = [
        %{"blue" => 255, "count" => 400, "green" => 0, "hex" => "#0000ff", "red" => 0},
        %{"blue" => 0, "count" => 225, "green" => 255, "hex" => "#00ff00", "red" => 0},
        %{"blue" => 0, "count" => 525, "green" => 0, "hex" => "#ff0000", "red" => 255},
        %{"blue" => 255, "count" => 1350, "green" => 255, "hex" => "#ffffff", "red" => 255}
      ]

      assert hist == expected
    end

    @tag timeout: 5000
    test ".auto_orient should not hang" do
      open(@fixture) |> auto_orient |> save
    end
  end
end

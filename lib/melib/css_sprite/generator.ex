defmodule Melib.CssSprite.Generator do
  @default_gap 5

  def generate(opts \\ []) do
    img_src_dir = opts |> Keyword.get(:img_src_dir)
    img_to_path = opts |> Keyword.get(:img_to_path)
    css_to_path = opts |> Keyword.get(:css_to_path)
    css_img_url = opts |> Keyword.get(:css_img_url)

    zoom = opts |> Keyword.get(:zoom, 1)

    css_class_shared = opts |> Keyword.get(:css_class_shared, "icon-nm")
    css_class_prefix = opts |> Keyword.get(:css_class_prefix, "icon-nm-")

    cond do
      blank?(img_src_dir) ->
        Melib.log_error(":img_src_dir can's blank")

      blank?(img_to_path) ->
        Melib.log_error(":img_to_path can's blank")

      blank?(css_to_path) ->
        Melib.log_error(":css_to_path can's blank")

      true ->
        perform_generate(%{
          zoom: zoom,
          img_src_dir: img_src_dir,
          img_to_path: img_to_path,
          css_img_url: css_img_url,
          css_to_path: css_to_path,
          css_class_shared: css_class_shared,
          css_class_prefix: css_class_prefix
        })
    end
  end

  defp perform_generate(opts) do
    %{
      zoom: zoom,
      img_src_dir: img_src_dir,
      img_to_path: img_to_path,
      css_img_url: css_img_url,
      css_to_path: css_to_path,
      css_class_shared: css_class_shared,
      css_class_prefix: css_class_prefix
    } = opts

    %{images: images, max_height: max_height, max_width: max_width} =
      img_src_dir
      |> read_images_from_dir
      |> put_coordinate(zoom: zoom)

    images
    |> write_css(
      css_to_path: css_to_path,
      css_class_shared: css_class_shared,
      css_class_prefix: css_class_prefix,
      css_img_url: css_img_url,
      max_height: max_height,
      zoom: zoom,
      max_width: max_width
    )
    |> write_image(
      img_to_path: img_to_path,
      max_height: max_height,
      max_width: max_width,
      zoom: zoom
    )
  end

  defp write_image(images, opts) do
    img_to_path = opts |> Keyword.get(:img_to_path)
    max_height = opts |> Keyword.get(:max_height)
    max_width = opts |> Keyword.get(:max_width)

    img_to_path |> Path.dirname() |> File.mkdir_p!()

    Melib.ImageMagick.run("convert", [
      "-size",
      "#{max_width}x#{max_height}",
      "xc:none",
      img_to_path
    ])

    images
    |> Enum.each(fn image ->
      Melib.ImageMagick.run("composite", [
        "-geometry",
        "+#{image.dirty.x}+#{image.dirty.y}",
        image.path,
        img_to_path,
        img_to_path
      ])
    end)

    Melib.log_info(["success write img file to: #{img_to_path}"])

    images
  end

  defp write_css(images, opts) do
    css_to_path = opts |> Keyword.get(:css_to_path)
    css_class_shared = opts |> Keyword.get(:css_class_shared)
    css_class_prefix = opts |> Keyword.get(:css_class_prefix)
    css_img_url = opts |> Keyword.get(:css_img_url)
    max_height = opts |> Keyword.get(:max_height)
    max_width = opts |> Keyword.get(:max_width)
    zoom = opts |> Keyword.get(:zoom)

    css_to_path |> Path.dirname() |> File.mkdir_p!()

    css_contents = []

    css_contents =
      List.insert_at(css_contents, -1, """
      .#{css_class_shared} {
      \s\sbackground-image: url(#{css_img_url});
      \s\sdisplay: inline-block;
      }

      .#{css_class_shared} {
      \s\sbackground-repeat: no-repeat;
      \s\sbackground-size: #{(max_width / zoom) |> to_i}px #{(max_height / zoom) |> to_i}px;
      }
      """)

    css_contents =
      Enum.reduce(images, css_contents, fn image, css_contents ->
        css_contents
        |> List.insert_at(-1, """
        .#{css_class_prefix}#{image.dirty.name |> String.downcase()} {
        \s\sbackground-position: #{(image.dirty.x / zoom) |> to_i}px -#{
          (image.dirty.y / zoom) |> to_i
        }px;
        \s\sheight: #{(image.height / zoom) |> to_i}px;
        \s\swidth: #{(image.width / zoom) |> to_i}px;
        }
        """)
      end)

    File.write!(css_to_path, Enum.join(css_contents, "\n"))
    Melib.log_info(["success write css file to: #{css_to_path}"])

    images
  end

  defp to_i(value) do
    Melib.Util.to_i(value)
  end

  defp blank?(str) do
    "#{str}" |> String.trim() |> String.length() == 0
  end

  defp file_image?(path) do
    path |> MIME.from_path() |> String.starts_with?("image/")
  end

  defp read_images_from_dir(img_src_dir) do
    img_src_dir
    |> File.ls!()
    |> Enum.sort()
    |> Enum.map(fn file_name ->
      file_path = img_src_dir |> Path.join(file_name)

      if not File.dir?(file_path) and file_image?(file_path) do
        case Melib.Mogrify.open(file_path) do
          %Melib.Image{} = media ->
            media |> Melib.Identify.put_width_and_height()

          _ ->
            nil
        end
      end
    end)
    |> Enum.filter(fn image -> !!image end)
  end

  defp put_coordinate(images, opts) do
    zoom = Keyword.get(opts, :zoom)
    gap = @default_gap * zoom

    start_value = %{images: [], max_height: 0, max_width: 0}

    Enum.reduce(images, start_value, fn image,
                                        %{
                                          images: images,
                                          max_height: max_height,
                                          max_width: max_width
                                        } ->
      dirty = image.dirty

      x = 0
      y = max_height

      dirty =
        dirty
        |> Map.put(:x, x)
        |> Map.put(:y, y)
        |> Map.put(:name, image.path |> Path.basename() |> Path.rootname())

      image = image |> Map.put(:dirty, dirty)

      max_width = if image.width > max_width, do: image.width, else: max_width
      max_height = image.height + max_height + gap
      images = images |> List.insert_at(-1, image)

      %{images: images, max_height: max_height, max_width: max_width}
    end)
  end
end

defmodule Melib.CssSprite.Generator do

  @default_gap 10

  def generate(opts \\ []) do
    img_src_dir = opts |> Keyword.get(:img_src_dir)
    img_to_path = opts |> Keyword.get(:img_to_path)
    css_to_path = opts |> Keyword.get(:css_to_path)

    scope_name = opts |> Keyword.get(:scope_name, "icon")
    css_class_shared = opts |> Keyword.get(:css_class_shared, "icon-nm")
    css_class_prefix = opts |> Keyword.get(:css_class_prefix, "icon-nm-")

    cond do
      blank?(img_src_dir) -> Melib.log_error(":img_src_dir 不能为空")
      blank?(img_to_path) -> Melib.log_error(":img_to_path 不能为空")
      blank?(css_to_path) -> Melib.log_error(":css_to_path 不能为空")
      true ->
        perform_generate(%{
          zoom: Keyword.get(opts, :zoom, 1),
          img_src_dir: img_src_dir,
          img_to_path: img_to_path,
          css_to_path: css_to_path,
          scope_name: scope_name,
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
      css_to_path: css_to_path,
      scope_name: scope_name,
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
      scope_name: scope_name,
      css_class_shared: css_class_shared,
      css_class_prefix: css_class_prefix,
      max_height: max_height,
      max_width: max_width
    )
    |> write_image(
      img_to_path: img_to_path,
      max_height: max_height,
      max_width: max_width
    )
  end

  defp write_image(images, opts) do
    img_to_path = opts |> Keyword.get(:img_to_path)
    max_height = opts |> Keyword.get(:max_height)
    max_width = opts |> Keyword.get(:max_width)

    Melib.system_cmd(
      "convert",
      [
        "-size",
        "#{max_width}x#{max_height}",
        "xc:none",
        img_to_path
      ]
    )

    images
    |> Enum.each(fn image ->
      Melib.system_cmd(
        "composite",
        [
          "-geometry",
          "+#{image.dirty.x}+#{image.dirty.y}",
          image.path,
          img_to_path,
          img_to_path
        ]
      )
    end)

    Melib.log_info(["success write img file to: #{img_to_path}"])

    images
  end

  defp write_css(images, opts) do
    css_to_path = opts |> Keyword.get(:css_to_path)
    # scope_name = opts |> Keyword.get(:scope_name)
    css_class_shared = opts |> Keyword.get(:css_class_shared)
    css_class_prefix = opts |> Keyword.get(:css_class_prefix)
    max_height = opts |> Keyword.get(:max_height)
    max_width = opts |> Keyword.get(:max_width)

    css_contents = []
    css_contents =
      List.insert_at(
        css_contents,
        -1,
        """
/* 将下面3行，放入页面中(仅供参考)
 .#{css_class_shared} {
   background-image: url(<%= image_path("...") %>);
 }
*/

.#{css_class_shared} {
  background-repeat: no-repeat;
  background-size: #{max_width}px #{max_height}px;
}
        """
      )

    css_contents =
      Enum.reduce(images, css_contents, fn image, css_contents ->
        css_contents
        |> List.insert_at(
        -1,
        """
.#{css_class_prefix}#{image.dirty.name |> String.downcase} {
  background-position: #{image.dirty.x}px -#{image.dirty.y}px;
  height: #{image.height}px;
  width: #{image.width}px;
}
        """
        )
      end)

    css_to_path |> Path.dirname |> File.mkdir_p!
    File.write!(css_to_path, Enum.join(css_contents, "\n"))
    Melib.log_info(["success write css file to: #{css_to_path}"])

    images
  end

  defp blank?(str) do
    ("#{str}" |> String.trim |> String.length) == 0
  end

  defp file_image?(path) do
    path |> MIME.from_path |> String.starts_with?("image/")
  end

  defp read_images_from_dir(img_src_dir) do
    img_src_dir
    |> File.ls!
    |> Enum.sort
    |> Enum.map(fn file_name ->
      file_path = img_src_dir |> Path.join(file_name)

      if not File.dir?(file_path) and file_image?(file_path) do
        case Melib.Mogrify.open(file_path) do
          %Melib.Image{} = media ->
            media |> Melib.Identify.put_width_and_height
          _ -> nil
        end

      end
    end)
    |> Enum.filter(fn image -> !!image end)
  end

  defp put_coordinate(images, opts) do
    zoom = Keyword.get(opts, :zoom)
    gap = @default_gap * zoom

    start_value = %{images: [], max_height: 0, max_width: 0}

    Enum.reduce(images, start_value, fn image, %{images: images, max_height: max_height, max_width: max_width} ->
      dirty = image.dirty

      x = gap
      y = max_height + gap

      dirty =
        dirty
        |> Map.put(:x, x)
        |> Map.put(:y, y)
        |> Map.put(:name, image.path |> Path.basename |> Path.rootname)

      image = image |> Map.put(:dirty, dirty)

      max_height = image.height + gap + max_height
      max_width = if image.width > max_width, do: image.width, else: max_width
      images = images |> List.insert_at(-1, image)

      %{images: images, max_height: max_height, max_width: max_width}
    end)
  end

end

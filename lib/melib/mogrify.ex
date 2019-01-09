defmodule Melib.Mogrify do
  @moduledoc """

  图片的基本操作

  * layers         # OptimizePlus
  * delay          # 25x100
  * loop           # 0
  * resize         # 设置大小
  * crop           # 裁剪
  * colorspace,    # 颜色空间
  * sample,        # 马赛克
  * charcoal,      # 手绘效果
  * contrast,      # 饱和度
  * blur,          # 模糊
  * quality,       # 图片质量
  * strip,         # 去掉extif
  * flatten,       # gif图片转jpg有用
  * mosiac,
  * "motion-blur", # 运动模糊
  * "auto-orient", # 自动方向
  * geometry,
  * composite,     # true/false
  * flop,          # 水平翻转
  * flip,          # 垂直翻转
  * background,    # 设置背景, 透明色：transparent
  * gravity,       # 坐标系, center, SouthEast, NorthEast
  * extent,        # 画布大小，300x300
  * alpha,         # 设置为透明：Set
  * trim,          # 是否减去白边 true/false,
  * border,        # 边框
  * bordercolor,   # 边框颜色,
  * sharpen,       # 锐化
  * shadow,        # 阴影
  * font,          # 参数为设置文字字体，值为字体文件的路径
  * fill,          # 设置文字颜色
  * pointsize      # 设置字体大小，单位为像素
  """

  alias Melib.Identify
  alias Melib.Compat
  alias Melib.Image

  @doc """
  Opens image source
  """
  def open(path) do
    path = Path.expand(path)

    unless File.exists?(path) do
      raise File.Error
    end

    unless File.regular?(path) do
      raise(File.Error)
    end

    %Image{path: path} |> Identify.verbose()
  end

  defp _process_image_gif(image) do
    format = image.format
    dirty_format = image.dirty |> Melib.get(:format, format)

    if format == "gif" && dirty_format != "gif" do
      image |> gif_thumbnail()
    else
      image
    end
  end

  @doc """
  Saves modified image

  ## Options

  * `:path` - The output path of the image. Defaults to a temporary file.
  * `:in_place` - Overwrite the original image, ignoring `:path` option. Default false.
  """
  def save(image, opts \\ []) do
    output_path = output_path_for(image, opts)
    Melib.system_cmd("mkdir", ["-p", Path.dirname(output_path)])
    postfix = Melib.get(image.dirty, :postfix, image.postfix)
    image = _process_image_gif(image)

    if File.exists?(output_path) do
      tmp_path = generate_temp_path(postfix)
      _mogrify_save(image, tmp_path, opts)
      File.cp!(tmp_path, output_path)
      File.rm!(tmp_path)
    else
      _mogrify_save(image, output_path, opts)
    end

    image
    |> image_after_command(output_path)
    |> Map.put(:verbosed, false)
  end

  defp _mogrify_save(image, output_path, opts) do
    Melib.ImageMagick.run(
      "mogrify",
      arguments_for_saving(image, output_path),
      stderr_to_stdout: true
    )

    if image.operations[:watermark] do
      Melib.ImageMagick.run(
        "composite",
        arguments_for_watermark(image, output_path, opts),
        stderr_to_stdout: true
      )
    end
  end

  defp hex_random(n) do
    n |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  def generate_temp_path(postfix \\ "") do
    System.tmp_dir() |> Path.join("melib-" <> hex_random(16) <> "#{postfix}")
  end

  @doc """
  Creates or saves image

  Uses the `convert` command, which accepts both existing images, or image
  operators. If you have an existing image, prefer save/2.

  ## Options

  * `:path` - The output path of the image. Defaults to a temporary file.
  * `:in_place` - Overwrite the original image, ignoring `:path` option. Default false.
  """
  def create(image, opts \\ []) do
    output_path = output_path_for(image, opts)
    Melib.system_cmd("mkdir", ["-p", Path.dirname(output_path)])
    postfix = Melib.get(image.dirty, :postfix, image.postfix)
    image = _process_image_gif(image)

    if File.exists?(output_path) do
      tmp_path = generate_temp_path(postfix)
      tmp_path |> Path.dirname() |> File.mkdir_p!()
      _mogrify_create(image, tmp_path, opts)
      File.cp!(tmp_path, output_path)
      File.rm!(tmp_path)
    else
      output_path |> Path.dirname() |> File.mkdir_p!()
      _mogrify_create(image, output_path, opts)
    end

    image
    |> image_after_command(output_path)
    |> Map.put(:verbosed, false)
  end

  defp _mogrify_create(image, output_path, opts) do
    Melib.ImageMagick.run(
      "convert",
      arguments_for_creating(image, output_path),
      stderr_to_stdout: true
    )

    if image.operations[:watermark] do
      Melib.ImageMagick.run(
        "composite",
        arguments_for_watermark(image, output_path, opts),
        stderr_to_stdout: true
      )
    end
  end

  ######### Begin set ########
  def set_layers(image, nil), do: image

  def set_layers(image, layers) do
    %{image | operations: image.operations ++ [layers: layers]}
  end

  def set_delay(image, nil), do: image

  def set_delay(image, delay) do
    %{image | operations: image.operations ++ [delay: delay]}
  end

  def set_loop(image, nil), do: image

  def set_loop(image, loop) do
    %{image | operations: image.operations ++ [loop: loop]}
  end

  def set_background(image, nil), do: image

  def set_background(image, background) do
    %{image | operations: image.operations ++ [background: background]}
  end

  def set_gif_src(image, nil), do: image

  def set_gif_src(image, gif_src) do
    %{image | operations: image.operations ++ [gif_src: gif_src]}
  end

  def set_path(image, nil), do: image

  def set_path(image, path) do
    %{image | path: path}
  end

  ######### END set ########

  def create_gif_from(sources, opts \\ []) do
    tmp_path = generate_temp_path()

    tmp_file_paths =
      sources
      |> Enum.with_index()
      |> Enum.map(fn {src, index} ->
        tmp_file_path = "#{tmp_path}_#{index}"
        File.copy!(src, tmp_file_path)
        tmp_file_path
      end)

    speed = opts |> Keyword.get(:speed, 1)

    image =
      opts
      |> Keyword.put(:layers, "OptimizePlus")
      |> Keyword.put(:delay, "#{25 * speed}x#{25 * length(sources)}")
      |> Keyword.put(:gif_src, "#{tmp_path}_*")
      |> _create_gif()

    tmp_file_paths |> Enum.each(fn path -> File.rm!(path) end)

    image
  end

  defp _create_gif(opts) when is_list(opts) do
    _create_gif(%Image{}, opts)
  end

  defp _create_gif(%Image{} = image) do
    _create_gif(image, [])
  end

  defp _create_gif(image, opts) do
    image =
      image
      |> set_path(opts[:path] || generate_temp_path(".gif"))
      |> set_gif_src(opts[:gif_src])
      |> set_layers(opts[:layers])
      |> set_delay(opts[:delay])
      |> set_loop(opts[:loop])

    output_path = image.path

    output_path |> Path.dirname() |> File.mkdir_p!()

    Melib.ImageMagick.run(
      "convert",
      arguments_for_gif_create(image, opts),
      stderr_to_stdout: true
    )

    output_path
    |> Identify.identify(identify: Keyword.get(opts, :identify, []))
    |> verbose
    |> image_after_command(output_path)
  end

  @doc """
  Returns the histogram of the image

  Runs ImageMagick's `histogram:info:-` command
  Results are returned as a list of maps where each map includes keys red, blue, green, hex and count

  Example:

  iex> open("test/fixtures/rbgw.png") |> histogram
  [
    %{"blue" => 255, "count" => 400, "green" => 0, "hex" => "#0000ff", "red" => 0},
    %{"blue" => 0, "count" => 225, "green" => 255, "hex" => "#00ff00", "red" => 0},
    %{"blue" => 0, "count" => 525, "green" => 0, "hex" => "#ff0000", "red" => 255},
    %{"blue" => 255, "count" => 1350, "green" => 255, "hex" => "#ffffff", "red" => 255}
  ]

  """
  def histogram(image) do
    img = image |> custom("format", "%c")
    args = arguments(img) ++ [image.path, "histogram:info:-"]

    Melib.ImageMagick.run("convert", args, stderr_to_stdout: false)
    |> elem(0)
    |> process_histogram_output
  end

  defp image_after_command(_image, output_path) do
    output_path
    |> Identify.identify()
    |> Identify.verbose(true)
  end

  defp histogram_integerify(hist) do
    hist
    |> Enum.into(%{}, fn {k, v} ->
      if k == "hex" do
        {k, v}
      else
        {k, v |> Compat.string_trim() |> String.to_integer()}
      end
    end)
  end

  defp extract_histogram_data(entry) do
    ~r/^\s+(?<count>\d+):\s+\((?<red>[\d\s]+),(?<green>[\d\s]+),(?<blue>[\d\s]+)\)\s+(?<hex>\#[abcdef\d]{6})\s+/
    |> Regex.named_captures(entry |> String.downcase())
    |> histogram_integerify
  end

  defp process_histogram_output(histogram_output) do
    histogram_output
    |> String.split("\n")
    |> Enum.reject(fn s -> s |> String.length() == 0 end)
    |> Enum.map(&extract_histogram_data/1)
  end

  defp output_path_for(image, save_opts) do
    if Keyword.get(save_opts, :in_place) do
      image.path
    else
      Keyword.get(save_opts, :path, temporary_path_for(image))
    end
  end

  defp arguments_for_saving(image, path) do
    base_arguments = ["-write", path, append_gif_frame_to_path(image)]
    arguments(image) ++ base_arguments
  end

  defp arguments_for_creating(image, path) do
    [append_gif_frame_to_path(image)] ++ arguments(image) ++ [path]
  end

  defp arguments_for_watermark(image, path, _opts) do
    watermark_arguments(image) ++ [path, path]
  end

  defp arguments_for_gif_create(image, _opts) do
    arguments(image) ++ [image.operations[:gif_src], image.path]
  end

  defp append_gif_frame_to_path(image) do
    if image.operations[:gif_frame] do
      image.path <> "[#{image.operations[:gif_frame]}]"
    else
      image.path
    end
  end

  defp watermark_arguments(image) do
    Enum.flat_map(image.operations[:watermark] || [], &normalize_arguments/1)
  end

  defp arguments(image) do
    Enum.flat_map(image.operations, &normalize_arguments/1)
  end

  defp normalize_arguments({option, :original}), do: ["#{option}"]
  defp normalize_arguments({:gif_frame, _gif_frame}), do: []
  defp normalize_arguments({:gif_src, _gif_src}), do: []
  defp normalize_arguments({:watermark, _watermark}), do: []
  defp normalize_arguments({:image_operator, params}), do: ~w(#{params})
  defp normalize_arguments({"annotate", params}), do: ~w(-annotate #{params})
  defp normalize_arguments({"histogram:" <> option, nil}), do: ["histogram:#{option}"]
  defp normalize_arguments({"+" <> option, nil}), do: ["+#{option}"]
  defp normalize_arguments({"-" <> option, nil}), do: ["-#{option}"]
  defp normalize_arguments({option, nil}), do: ["-#{option}"]
  defp normalize_arguments({"+" <> option, params}), do: ["+#{option}", to_string(params)]
  defp normalize_arguments({"-" <> option, params}), do: ["-#{option}", to_string(params)]
  defp normalize_arguments({option, params}), do: ["-#{option}", to_string(params)]

  @doc """
  Makes a copy of original image
  """
  def copy(image) do
    temp = temporary_path_for(image)
    File.cp!(image.path, temp)
    Map.put(image, :path, temp)
  end

  def temporary_path_for(%{dirty: %{path: dirty_path, postfix: postfix}} = _image) do
    _temporary_path_for(dirty_path, postfix)
  end

  def temporary_path_for(%{path: path, postfix: postfix} = _image) do
    _temporary_path_for(path, postfix)
  end

  defp _temporary_path_for(path, postfix) do
    tmp_path = System.tmp_dir() |> Path.join("melib-#{hex_random(16)}-#{Path.basename(path)}")
    "#{Path.rootname(tmp_path)}#{postfix}"
  end

  @doc """
  Provides detailed information about the image
  """
  def verbose(%Melib.Image{verbosed: false} = image) do
    image |> Identify.verbose()
  end

  def verbose(attachment), do: attachment

  def dev_null do
    case :os.type() do
      {:win32, _} -> "NUL"
      _ -> "/dev/null"
    end
  end

  def normalize_verbose_term({"animated", "[0]"}), do: {:animated, true}
  def normalize_verbose_term({"animated", ""}), do: {:animated, false}

  def normalize_verbose_term({key, value}) when key in ["width", "height"] do
    {String.to_atom(key), String.to_integer(value)}
  end

  def normalize_verbose_term({key, value}), do: {String.to_atom(key), String.downcase(value)}

  @doc """
  Converts the image to the image format you specify
  """
  def format(image, format) do
    downcase_format = String.downcase(format)

    postfix =
      if downcase_format && downcase_format != "" do
        "." <> downcase_format
      else
        ""
      end

    ext = ".#{downcase_format}"
    rootname = Path.rootname(image.path, image.ext)

    dirty =
      image.dirty
      |> Map.put(:path, "#{rootname}#{ext}")
      |> Map.put(:format, downcase_format)
      |> Map.put(:postfix, postfix)
      |> Map.put(:mime_type, MIME.type(downcase_format))

    %{image | operations: image.operations ++ [format: format], dirty: dirty}
  end

  @doc """
  Resizes the image with provided geometry
  """
  def resize(image, params) do
    %{image | operations: image.operations ++ [resize: params]}
  end

  @doc """
  Extends the image to the specified dimensions
  """
  def extent(image, params) do
    %{image | operations: image.operations ++ [extent: params]}
  end

  @doc """
  Sets the gravity of the image
  """
  def gravity(image, params) do
    %{image | operations: image.operations ++ [gravity: params]}
  end

  @doc """
  Resize the image to fit within the specified dimensions while retaining
  the original aspect ratio. Will only resize the image if it is larger than the
  specified dimensions. The resulting image may be shorter or narrower than specified
  in the smaller dimension but will not be larger than the specified values.
  """
  def resize_to_limit(image, params) do
    resize(image, "#{params}>")
  end

  @doc """
  Resize the image to fit within the specified dimensions while retaining
  the aspect ratio of the original image. If necessary, crop the image in the
  larger dimension.
  """
  def resize_to_fill(image, params) do
    [_, width, height] = Regex.run(~r/(\d+)x(\d+)/, params)

    image =
      if image.width && image.height do
        image
      else
        Melib.Mogrify.verbose(image)
      end

    {width, _} = Float.parse(width)
    {height, _} = Float.parse(height)
    cols = image.width
    rows = image.height

    if width != cols || height != rows do
      scale_x = width / cols
      scale_y = height / rows
      larger_scale = max(scale_x, scale_y)
      cols = (larger_scale * (cols + 0.5)) |> Float.round()
      rows = (larger_scale * (rows + 0.5)) |> Float.round()
      image = resize(image, if(scale_x >= scale_y, do: "#{cols}", else: "x#{rows}"))

      if width != cols || height != rows do
        extent(image, params)
      else
        image
      end
    else
      image
    end
  end

  def auto_orient(image) do
    %{image | operations: image.operations ++ ["auto-orient": nil]}
  end

  def strip(image) do
    %{image | operations: image.operations ++ [strip: nil]}
  end

  def quality(image, quality) do
    %{image | operations: image.operations ++ [quality: quality]}
  end

  def gif_thumbnail(image, opts \\ []) do
    gif_frame = opts |> Keyword.get(:gif_frame, 0)
    %{image | operations: image.operations ++ [gif_frame: gif_frame]}
  end

  @doc """
  opts:
  * gravity
  * geometry
  * min_height
  * min_width
  """
  def watermark(image, watermark, opts \\ []) do
    image = image |> Identify.verbose()
    operations = image.operations
    height_valid = !opts[:min_height] or !image.height or image.height >= opts[:min_height]
    width_valid = !opts[:min_width] or !image.width or image.width >= opts[:min_width]
    skip = image.mime_type == "image/gif" and !!opts[:gif_skip]

    if height_valid && width_valid && !skip do
      watermark_opts = [
        gravity: opts |> Keyword.get(:gravity, "SouthEast"),
        geometry: opts |> Keyword.get(:geometry, "+0+0"),
        "#{watermark}": :original
      ]

      %{image | operations: operations ++ [watermark: watermark_opts]}
    else
      image
    end
  end

  @doc """
  opts:
  * x
  * y
  * text
  * gravity
  * fill
  * pointsize
  * font
  """
  def draw_text(image, opts \\ []) do
    font = opts |> Keyword.get(:font) |> Melib.Config.get_font()

    operations =
      (image.operations ++
         [
           gravity: opts |> Keyword.get(:gravity, "SouthEast"),
           fill: opts |> Keyword.get(:fill, "black")
         ])
      |> Melib.if_call(font, fn operations ->
        operations ++ [font: font]
      end)
      |> Melib.if_call(true, fn operations ->
        x = Keyword.get(opts, :x, 0)
        y = Keyword.get(opts, :y, 0)
        text = Keyword.get(opts, :text, "")
        font_size = Keyword.get(opts, :font_size, 32)

        operations ++ [draw: "font-size #{font_size} text +#{x},+#{y} '#{text}'"]
      end)

    %{image | operations: operations}
  end

  def canvas(image, color) do
    image_operator(image, "xc:#{color}")
  end

  def custom(image, action, options \\ nil) do
    %{image | operations: image.operations ++ [{action, options}]}
  end

  def image_operator(image, operator) do
    %{image | operations: image.operations ++ [{:image_operator, operator}]}
  end
end

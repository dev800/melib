defmodule Melib.Mogrify do
  @moduledoc """
  图片的基本操作
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

    %Image{path: path} |> Identify.put_mime_type()
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

    if File.exists?(image.path) do
      tmp_path = generate_temp_path()

      Melib.ImageMagick.run(
        "mogrify",
        arguments_for_saving(image, tmp_path),
        stderr_to_stdout: true
      )

      if image.operations[:watermark] do
        Melib.ImageMagick.run(
          "composite",
          arguments_for_watermark(image, tmp_path, opts),
          stderr_to_stdout: true
        )
      end

      File.cp!(tmp_path, output_path)
      File.rm!(tmp_path)
    else
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

    image_after_command(image, output_path)
  end

  defp hex_random(n) do
    n |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  defp generate_temp_path do
    System.tmp_dir() |> Path.join("melib-" <> hex_random(16))
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

    if File.exists?(image.path) do
      tmp_path = generate_temp_path()

      Melib.ImageMagick.run(
        "convert",
        arguments_for_creating(image, tmp_path),
        stderr_to_stdout: true
      )

      if image.operations[:watermark] do
        Melib.ImageMagick.run(
          "composite",
          arguments_for_watermark(image, tmp_path, opts),
          stderr_to_stdout: true
        )
      end

      File.cp!(tmp_path, output_path)
      File.rm!(tmp_path)
    else
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

    image_after_command(image, output_path)
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

  defp image_after_command(image, output_path) do
    format = Map.get(image.dirty, :format, image.format)
    postfix = Map.get(image.dirty, :postfix, image.postfix)

    %{
      image
      | path: output_path,
        ext: Path.extname(output_path),
        format: format,
        postfix: postfix,
        operations: [],
        dirty: %{}
    }
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
  defp normalize_arguments({:gif_frame, _watermark}), do: []
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

  def temporary_path_for(%{dirty: %{path: dirty_path}} = _image) do
    do_temporary_path_for(dirty_path)
  end

  def temporary_path_for(%{path: path} = _image) do
    do_temporary_path_for(path)
  end

  defp do_temporary_path_for(path) do
    name = Path.basename(path)
    random = Compat.rand_uniform(999_999)
    Path.join(System.tmp_dir(), "#{random}-#{name}")
  end

  @doc """
  Provides detailed information about the image
  """
  def verbose(image) do
    args = ~w(-verbose -write #{dev_null()}) ++ [image.path]
    {output, 0} = Melib.ImageMagick.run("mogrify", args, stderr_to_stdout: true)

    info =
      ~r/\b(?<animated>\[0])? (?<format>\S+) (?<width>\d+)x(?<height>\d+)/
      |> Regex.named_captures(output)
      |> Enum.map(&normalize_verbose_term/1)
      |> Enum.into(%{})
      |> put_frame_count(output)

    Map.merge(image, info)
  end

  defp dev_null do
    case :os.type() do
      {:win32, _} -> "NUL"
      _ -> "/dev/null"
    end
  end

  defp normalize_verbose_term({"animated", "[0]"}), do: {:animated, true}
  defp normalize_verbose_term({"animated", ""}), do: {:animated, false}

  defp normalize_verbose_term({key, value}) when key in ["width", "height"] do
    {String.to_atom(key), String.to_integer(value)}
  end

  defp normalize_verbose_term({key, value}), do: {String.to_atom(key), String.downcase(value)}

  defp put_frame_count(%{animated: false} = map, _), do: Map.put(map, :frame_count, 1)

  defp put_frame_count(map, text) do
    # skip the [0] lines which may be duplicated
    matches = Regex.scan(~r/\b\[[1-9][0-9]*] \S+ \d+x\d+/, text)
    # add 1 for the skipped [0] frame
    frame_count = length(matches) + 1
    Map.put(map, :frame_count, frame_count)
  end

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
    image = Melib.Mogrify.verbose(image)
    {width, _} = Float.parse(width)
    {height, _} = Float.parse(height)
    cols = image.width
    rows = image.height

    if width != cols || height != rows do
      # .to_f
      scale_x = width / cols
      # .to_f
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
    image = image |> Identify.put_width_and_height()
    operations = image.operations
    height_valid = !opts[:min_height] or !image.height or image.height >= opts[:min_height]
    width_valid = !opts[:min_width] or !image.width or image.width >= opts[:min_width]
    skip = image.mime_type == "image/gif" and !!opts[:gif_skip]

    if height_valid && width_valid && !skip do
      watermark_opts = []

      watermark_opts =
        if Keyword.has_key?(operations, :gravity) do
          watermark_opts
        else
          watermark_opts ++ [gravity: opts |> Keyword.get(:gravity, "SouthEast")]
        end

      watermark_opts =
        if Keyword.has_key?(operations, :geometry) do
          watermark_opts
        else
          watermark_opts ++ [geometry: opts |> Keyword.get(:geometry, "+0+0")]
        end

      watermark_opts = watermark_opts ++ ["#{watermark}": :original]

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
    operations = image.operations

    operations =
      if Keyword.has_key?(operations, :gravity) do
        operations
      else
        operations ++ [gravity: opts |> Keyword.get(:gravity, "SouthEast")]
      end

    operations =
      if Keyword.has_key?(operations, :fill) do
        operations
      else
        operations ++ [fill: opts |> Keyword.get(:fill, "black")]
      end

    operations =
      if Keyword.has_key?(operations, :pointsize) do
        operations
      else
        # TODO: 字体大小应该根据图片的大小自适应一下
        operations ++ [pointsize: opts |> Keyword.get(:pointsize, 16)]
      end

    operations =
      if Keyword.has_key?(operations, :font) do
        operations
      else
        operations ++ [font: opts |> Keyword.get(:font, :msyh) |> get_font]
      end

    operations =
      operations ++
        [
          draw:
            "text +#{Keyword.get(opts, :x, 0)},+#{Keyword.get(opts, :y, 0)} '#{
              Keyword.get(opts, :text, "")
            }'"
        ]

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

  def get_font(:msyh) do
    Path.join(:code.priv_dir(:melib), "/font/MSYH.TTC") |> Path.expand()
  end

  def get_font(path) when is_binary(path), do: Path.expand(path)

  def get_font(_) do
    Path.join(:code.priv_dir(:melib), "/font/JDJSTE.TTF") |> Path.expand()
  end
end

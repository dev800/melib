defmodule Melib.Captcha do
  alias Melib.{
    Mogrify,
    Config
  }

  @doc """
  生成验证码

  控制参数：
  * `size` - 验证码图片大小，默认值：`100x40`，宽100，高40
  * `font` - 验证码字体名，需要在配置文件中配置字体名和字体文件绝对路径的映射，例如`jdjste: "path/to/JDJSTE.TTF"`
  * `font_width` - 验证码内容文字加粗，默认值：1
  * `bezier_width` - 干扰线加粗, 默认值：2
  * `bezier` - 干扰线条数, 默认值：3
  * `label` - 验证码内容
  * `point_size` - 字体大小，默认为20
  * `noise` - 增加噪点，可选样式：
  `Gaussian`、`Impulse`、`Laplacian`、`Multiplicative`、`Poisson`、`Uniform`，
  默认为`Uniform`无噪点
  """
  def render(opts \\ [])

  def render(opts) when is_list(opts) do
    opts
    |> Map.new()
    |> render()
  end

  def render(opts) do
    path = Mogrify.generate_temp_path() <> ".png"
    path |> Path.expand() |> Path.dirname() |> File.mkdir_p!()
    path |> File.touch!()

    params =
      ["xc:[#{opts[:size] || "100x40"}!]"]
      |> _append_params(:pointsize, "#{opts[:point_size] || opts[:pointsize] || 20}")
      |> _append_params(:font, Config.get_font(opts[:font] || :default))
      |> _append_params(:gravity, "NorthWest")
      |> _append_params(:strokewidth, "#{opts[:font_width] || 1}")
      |> _append_label(opts)
      |> _append_params(:strokewidth, "#{opts[:bezier_width] || 2}")
      |> _append_params(:stroke, random_rgba())
      |> _append_params(:fill, "rgba(0, 0, 0, 0)")
      |> _gen_bezier(opts[:bezier] || 3)

    params = params ++ ["+noise", opts[:noise] || "Uniform"] ++ [path]

    case Melib.ImageMagick.run("convert", params) do
      {_, 0} ->
        {:ok, path}

      _ ->
        {:error, :convert_fail}
    end
  end

  def random_rgba do
    "rgba(#{Enum.random(0..255)}, #{Enum.random(0..255)}, #{Enum.random(0..255)}, 0.3)"
  end

  # 指定干扰线条数，但不能保证所有线一定都在图片上，干扰线位置由函数计算结果而定
  defp _gen_bezier(params, 0), do: params

  defp _gen_bezier(params, index) do
    bezier = "bezier #{random_coor()} #{random_coor()} #{random_coor()} #{random_coor()}"

    params
    |> _append_params(:draw, bezier)
    |> _gen_bezier(index - 1)
  end

  defp random_coor(list \\ -50..100) do
    "#{Enum.random(list)},#{Enum.random(list)}"
  end

  defp _append_params(params, key, value) do
    params ++ ["-#{key}", value]
  end

  defp _append_label(params, opts) do
    chars =
      (opts[:label] || "")
      |> String.split("", trim: true)

    count = Enum.count(chars)
    size = get_size(opts[:size] || "100x40")
    x_per_char = div(elem(size, 0), count * 2 + 1)

    1..count
    |> Enum.map(& &1)
    |> Enum.reduce(params, fn index, params ->
      char_generator(params, chars, x_per_char, index, size)
    end)
  end

  def char_generator(params, chars, x_per_char, index, size) do
    params
    |> _append_params(:fill, random_rgb())
    |> _append_params(:stroke, random_rgb())
    |> _append_params(:draw, random_position(chars, x_per_char, index, elem(size, 1)))
  end

  # 生成随机16进制rgb值
  def random_rgb do
    rgb =
      1..3
      |> Enum.map(fn _x ->
        Enum.random(0..255)
        |> Integer.to_string(16)
        |> _format_value()
      end)
      |> Enum.join("")

    "##{rgb}"
  end

  defp _format_value(str) do
    if(String.length(str) == 1, do: "0" <> str, else: str)
  end

  # 生成随机纵向坐标值，计算横向横向坐标值
  def random_position(chars, x_per_char, index, height) do
    x = ((index - 1) * 2 + 1) * x_per_char
    y = Enum.random(15..(height - 15))
    rotate = Enum.random(-30..30)
    {char, _} = List.pop_at(chars, index - 1)

    "translate #{x},#{y} rotate #{rotate} text 0,-8 \"#{char}\""
  end

  def get_size(size) do
    size
    |> String.split("x")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end
end

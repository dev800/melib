defmodule Melib.Captcha.Render do
  @image_styles %{
    "embosed_silver" => [{:fill, "darkblue"}, {:shade, "20x60"}, {:background, "white"}],
    "simply_red" => [{:fill, "darkred"}, {:background, "white"}],
    "simply_green" => [{:fill, "darkgreen"}, {:background, "white"}],
    "simply_blue" => [{:fill, "darkblue"}, {:background, "white"}],
    "distorted_black" => [{:fill, "darkblue"}, {:edge, 10}, {:background, "white"}],
    "black" => [{:fill, "darkblue"}, {:edge, 2}, {:background, "white"}],
    "charcoal_grey" => [{:fill, "darkblue"}, {:charcoal, 5}, {:background, "white"}],
    "almost_invisible" => [{:fill, "red"}, {:solarize, 50}, {:background, "white"}]
  }

  @doc """
  ## Params

  * opts
    - style
    - label
  """
  def render(opts \\ [])
  def render(opts) when is_list(opts), do: Map.new(opts) |> render

  def render(opts) do
    style = Map.get(opts, :style, "random")

    style_params =
      cond do
        Map.has_key?(@image_styles, style) ->
          @image_styles[style] |> Map.new()

        true ->
          @image_styles
          |> Map.values()
          |> Enum.shuffle()
          |> List.first()
          |> Map.new()
      end

    path = Melib.Mogrify.generate_temp_path() <> ".png"
    path |> Path.expand() |> Path.dirname() |> File.mkdir_p!()
    path |> File.touch!()
    params = opts |> Map.merge(style_params)
    convert(path, params)
  end

  @doc """
  ## Params

  * opts
    - wave        频率
    - implode     內爆
    - pointsize   字的点数
    - size        图片尺寸
    - gravity     "Center"
    - label       文字内容
    - path        输出路径
    - fill        填充色
    - shade       阴影
    - background  背景
    - edge        边缘
    - charcoal    木炭
    - solarize    曝光
  """
  def convert(path, opts \\ []) do
    params =
      []
      |> _append_params(:gravity, opts, "Center")
      |> _append_params(:font, opts, Melib.Config.get_font(opts[:font] || :default))
      |> _append_params(:wave, opts)
      |> _append_params(:implode, opts)
      |> _append_params(:pointsize, opts)
      |> _append_params(:size, opts)
      |> _append_params(:fill, opts)
      |> _append_params(:shade, opts)
      |> _append_params(:background, opts)
      |> _append_params(:edge, opts)
      |> _append_params(:charcoal, opts)
      |> _append_params(:solarize, opts)

    params = if opts[:label], do: params ++ ["label:#{opts[:label]}"], else: params
    params = if path, do: params ++ ["#{path}"], else: params

    "convert"
    |> Melib.system_cmd(params)
    |> case do
      {_, 0} -> {:ok, path}
      _ -> {:error, :convert_fail}
    end
  end

  defp _append_params(params, key, opts, default \\ nil) do
    if value = opts[key] || default do
      params ++ ["-#{key}", value]
    else
      params
    end
  end
end

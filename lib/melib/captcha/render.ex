defmodule Melib.Captcha.Render do
  def render(opts \\ []) do

  end

  @doc """
  ## Params

  * opts
    - wave        频率
    - implode     內爆
    - pointsize   字的点数
    - size        图片尺寸
    - gravity     'Center'
    - label       文字内容
    - path        输出路径
    - fill        填充色
    - shade       阴影
    - background  背景
    - edge        边缘
    - charcoal    木炭
    - solarize    曝光
  """
  def convert(opts \\ []) do
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
    params = if opts[:path], do: params ++ ["#{opts[:path]}"], else: params
    Melib.system_cmd("convert", params)
  end

  defp _append_params(params, key, opts, default \\ nil) do
    if value = opts[key] || default do
      params ++ ["-#{key}", value]
    else
      params
    end
  end
end

defmodule Melib.Convert do
  @moduledoc """
  封装了一些渐变的图片转换的方法，便于快速调用
  """

  def convert(source, opts \\ [])

  def convert({:file, file}, opts) do
    path = Melib.Mogrify.generate_temp_path()
    path |> File.write!(file)
    {:path, path} |> convert(opts)
  end

  def convert({:path, path}, opts) do
    path |> Melib.Identify.identify |> convert(opts)
  end

  @doc """
  ## opts

  * `resize_to_fill`
  * `resize_to_limit`
  * format
  * auto_orient
  * strip
  * quality
  * thumbnail
  * draw_text
  * watermark

  ## Example Config

  %{
    styles: %{
      thumb: %{
        convert: [
          # 自动方向
          auto_orient: true,
          strip: true,
          quality: 90,
          thumbnail: true,
          # 高度限定，宽度随意
          resize_to_limit: "x120"
        ]
      },
      small: %{
        convert: [
          # 自动方向
          auto_orient: true,
          strip: true,
          quality: 90,
          thumbnail: true,
          # 中间截取的方形小图
          resize_to_fill: "120x120"
        ]
      },
      normal: %{
        convert: [
          # 自动方向
          auto_orient: true,
          strip: true,
          quality: 90,
          thumbnail: true,
          # 中间截取的方形中图
          resize_to_fill: "280x280"
        ]
      },
      preview: %{
        convert: [
          watermark: [
            Path.join(:code.priv_dir(:giabbs), "/assets/images/watermarks/giabbs/preview.png"),
            gif_skip: true,
            gravity: _random_gravity(),
            min_height: 300,
            min_width: 400
          ],
          # 自动方向
          auto_orient: true,
          strip: true,
          quality: 70,
          resize_to_limit: "560>"
        ]
      },
      great: %{
        convert: [
          watermark: [
            Path.join(:code.priv_dir(:giabbs), "/assets/images/watermarks/giabbs/great.png"),
            gif_skip: true,
            gravity: _random_gravity(),
            min_height: 300,
            min_width: 400
          ],
          # 自动方向
          auto_orient: true,
          strip: true,
          quality: 75,
          resize_to_limit: "1280>"
        ]
      },
      large: %{
        convert: [
          watermark: [
            Path.join(:code.priv_dir(:giabbs), "/assets/images/watermarks/giabbs/large.png"),
            gif_skip: true,
            gravity: _random_gravity(),
            min_height: 300,
            min_width: 400
          ],
          # 自动方向
          auto_orient: true,
          strip: true,
          quality: 70,
          resize_to_limit: "720>"
        ]
      },
      super: %{
        convert: [
          # 自动方向
          auto_orient: true,
          strip: true,
          quality: 95,
          resize_to_limit: "1280>"
        ]
      }
    }
  }
  """
  def convert(%Melib.Image{} = image, opts) do
    image
    |> Melib.if_call(opts[:gravity], fn image ->
      image |> Melib.Mogrify.gravity(opts[:gravity] || "center")
    end)
    |> Melib.if_call(opts[:resize_to_fill], fn image ->
      image |> Melib.Mogrify.resize_to_fill(opts[:resize_to_fill] || "")
    end)
    |> Melib.if_call(opts[:resize_to_limit], fn image ->
      image |> Melib.Mogrify.resize_to_limit(opts[:resize_to_limit] || "")
    end)
    |> Melib.if_call(opts[:format], fn image ->
      image |> Melib.Mogrify.format(opts[:format])
    end)
    |> Melib.if_call(opts[:auto_orient], fn image ->
      image |> Melib.Mogrify.auto_orient()
    end)
    |> Melib.if_call(opts[:strip], fn image ->
      image |> Melib.Mogrify.strip()
    end)
    |> Melib.if_call(opts[:quality], fn image ->
      image |> Melib.Mogrify.quality(opts[:quality])
    end)
    |> Melib.if_call(opts[:thumbnail], fn image ->
      image |> Melib.Mogrify.gif_thumbnail()
    end)
    |> Melib.if_call(opts[:draw_text], fn image ->
      image |> Melib.Mogrify.draw_text(opts[:draw_text] || [])
    end)
    |> Melib.if_call(opts[:watermark], fn image ->
      case List.pop_at(opts[:watermark], 0) do
        {watermark, watermark_opts} ->
          if watermark do
            image |> Melib.Mogrify.watermark(watermark, watermark_opts)
          else
            image
          end

        _ ->
          image
      end
    end)
    |> Melib.Mogrify.create()
    |> Melib.Identify.put_width_and_height(true)
  end

  def convert(other, _opts), do: other
end

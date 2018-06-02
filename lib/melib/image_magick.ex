defmodule Melib.ImageMagick do

  @moduledoc """
  config :melib, :magick_path, "/usr/local/ImageMagick6/bin"

  or

  config :melib, :magick_path, "/usr/local/ImageMagick7/bin"
  """

  @magick_path Application.get_env(:melib, :magick_path, "")

  def run(cmd, args, opts \\ []) do
    @magick_path
    |> Path.join(cmd)
    |> Melib.system_cmd(args, opts)
  end
end

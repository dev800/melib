defmodule Melib.ImageMagick do

  @moduledoc """
  config :melib, :magick_path, "/usr/local/ImageMagick6/bin"

  or

  config :melib, :magick_path, "/usr/local/ImageMagick7/bin"
  """

  def run(cmd, args, opts \\ []) do
    Application.get_env(:melib, :magick_path, "")
    |> Path.join(cmd)
    |> Melib.system_cmd(args, opts)
  end
end

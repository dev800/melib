defmodule Melib.Logger do
  require Logger

  @default_options [pretty: true, charlists: false]

  def log_inspect(info, options \\ []) do
    options = @default_options |> Keyword.merge(options)
    inspect(info, options)
  end

  def log_debug(info, options \\ []) do
    info |> log_inspect |> Logger.debug(options)
  end

  def log_info(info, options \\ []) do
    info |> log_inspect |> Logger.info(options)
  end

  def log_warn(info, options \\ []) do
    info |> log_inspect |> Logger.warn(options)
  end

  def log_error(info, options \\ []) do
    info |> log_inspect |> Logger.error(options)
  end
end

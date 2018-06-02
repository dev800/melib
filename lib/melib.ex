defmodule Melib do
  @moduledoc """
  媒体工具，例如：图片，视频，gif等
  """

  @logger Application.get_env(:melib, :logger, Melib.Logger)

  def if_call(q, condition, true_fn) do
    if condition, do: true_fn.(q), else: q
  end

  defdelegate log_debug(info \\ nil, opts \\ []), to: @logger
  defdelegate log_info(info \\ nil, opts \\ []), to: @logger
  defdelegate log_warn(info \\ nil, opts \\ []), to: @logger
  defdelegate log_error(info \\ nil, opts \\ []), to: @logger
  defdelegate log_inspect(info \\ nil, opts \\ []), to: @logger

  def log(info \\ nil, opts \\ []) do
    case Logger.level() do
      :debug -> log_debug(info, opts)
      :info -> log_info(info, opts)
      :warn -> log_warn(info, opts)
      :error -> log_error(info, opts)
      _ -> log_debug(info, opts)
    end
  end

  def expand_path(path) do
    path |> String.replace_leading("~", Path.expand("~"))
  end

  def system_cmd(command, args, opts \\ []) do
    args = args |> Enum.map(fn arg -> "#{arg}" end)
    start_at = Timex.now()
    log_string = [command, Enum.join(args, " ")] |> Enum.join(" ")

    ["start: #{log_string} with options: #{inspect(opts)}"]
    |> normalize_logger_args
    |> log_info(pretty: false)

    result = System.cmd(command, args, opts)

    [
      "finish: #{log_string} with options: #{inspect(opts)} in #{
        Timex.diff(Timex.now(), start_at) / 1000
      }ms"
    ]
    |> normalize_logger_args
    |> log_info(pretty: false)

    result
  end

  defp normalize_logger_args(args) do
    args
  end

  def md5_hash(string), do: :crypto.hash(:md5, "#{string}")

  def md5(string) do
    string |> md5_hash |> Base.encode16(case: :lower)
  end

  def sha256_hash(string), do: :crypto.hash(:sha256, "#{string}")

  def sha256(string) do
    string |> sha256_hash |> Base.encode16(case: :lower)
  end

  def sha512_hash(string), do: :crypto.hash(:sha512, "#{string}")

  def sha512(string) do
    string |> sha512_hash |> Base.encode16(case: :lower)
  end
end

use Mix.Config

config :logger, level: :warn

config :melib, :fonts, %{
  default: Path.join(__DIR__, "../test/fixtures/fonts/JDJSTE.TTF")
}

defmodule Melib.Mixfile do
  use Mix.Project

  def project do
    [
      app: :melib,
      name: "Melib",
      version: "0.1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Lib for elixir",
      source_url: "https://github.com/gialib/melib",
      homepage_url: "https://github.com/gialib/melib",
      package: package(),
      docs: [
        extras: ["README.md"],
        main: "readme"
      ]
    ]
  end

  def application do
    [
      applications: [
        :timex
      ]
    ]
  end

  defp deps do
    [
      {:qrcode, "~> 0.0"},
      {:mime, "~> 1.2"},
      {:timex, "~> 3.0"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp package do
    %{
      files: ["priv", "lib", "mix.exs", "README*"],
      maintainers: ["happy"],
      licenses: ["BSD 3-Clause"],
      links: %{"Github" => "https://github.com/gialib/melib"}
    }
  end
end

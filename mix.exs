defmodule Melib.Mixfile do
  use Mix.Project

  def project do
    [
      app: :melib,
      name: "Melib",
      version: "0.1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Lib for elixir",
      source_url: "https://github.com/dev800/melib",
      homepage_url: "https://github.com/dev800/melib",
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
      {:jason, "~> 1.0"},
      {:qrcode, "~> 0.0"},
      {:mime, "~> 1.2"},
      {:timex, "~> 3.0"},
      {:inch_ex, "~> 0.0", only: :docs},
      {:ex_doc, "~> 0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    %{
      files: ["priv", "lib", "mix.exs", "README*"],
      maintainers: ["happy"],
      licenses: ["BSD 3-Clause"],
      links: %{"Github" => "https://github.com/dev800/melib"}
    }
  end
end

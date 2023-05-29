defmodule Train.MixProject do
  use Mix.Project

  @version "0.0.1-dev"
  @url "https://github.com/ricardohsd/train"

  def project do
    [
      app: :train,
      version: @version,
      elixir: "~> 1.14",
      description: "LLM chain for Elixir",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @url,
      homepage_url: @url,
      licenses: licenses(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:ex_tiktoken, "~> 0.1.1"},
      {:abacus, "~> 0.4.2"},
      {:exvcr, "~> 0.11", only: :test}
    ]
  end

  defp licenses, do: ~w(MIT)

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end
end

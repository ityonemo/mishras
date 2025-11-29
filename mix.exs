defmodule Mishras.MixProject do
  use Mix.Project

  def project do
    [
      app: :mishras,
      version: "0.2.1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test,
      package: [
        description: "Factory Library for Ecto schemas",
        licenses: ["MIT"],
        files: ~w(lib mix.exs README* LICENSE*),
        links: %{
          "GitHub" => "https://github.com/ityonemo/mishras",
          "Mishras" => "https://hexdocs.pm/mishras"
        }
      ],
      docs: docs()
    ]
  end

  defp docs do
    [
      main: "Mishras.Factory"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/_support"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:protoss, "> 0.0.0", runtime: false},
      {:mox, "> 0.0.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end

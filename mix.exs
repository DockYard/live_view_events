defmodule LiveViewEvents.MixProject do
  use Mix.Project

  @source_url "https://github.com/DockYard/live_view_events"
  @version "0.2.0"

  def project do
    [
      app: :live_view_events,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      license: "MIT",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      extras: [{:"README.md", [title: "Overview"]}],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  def package do
    [
      maintainers: ["Sergio Arbeo"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib LICENSE.md mix.exs README.md),
      description:
        "A library to unify and simplify sending messages between components and views in the server for Phoenix LiveView."
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7.5", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4.3", only: :dev, runtime: false},
      {:ex_doc, "~> 0.31.2", only: :dev, runtime: false},
      {:floki, ">= 0.36.0", only: :test},
      {:phoenix_live_view, "~> 0.19 or ~> 1.0"}
    ]
  end
end

defmodule LiveViewEvents.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_view_events,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_view, "~> 0.19"}
    ]
  end
end

defmodule LiveDashboardHistory.MixProject do
  use Mix.Project
  @version "0.2.6"

  def project do
    [
      app: :live_dashboard_history,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      description: "Ephemeral metrics history storage for Phoenix LiveDashboard",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {LiveDashboardHistory.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      dev: "run --no-halt dev.exs"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_dashboard,
       git: "https://github.com/bglusman/phoenix_live_dashboard.git", branch: "historical_data"},
      {:circular_buffer, git: "https://github.com/keathley/circular_buffer.git"}
    ]
  end
end

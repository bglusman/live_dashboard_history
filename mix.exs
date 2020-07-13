defmodule LiveDashboardHistory.MixProject do
  use Mix.Project
  @version "0.1.0"

  def project do
    [
      app: :live_dashboard_history,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      name: "LiveDashboardHistory",
      docs: docs(),
      package: package(),
      homepage_url: "http://github.com/bglusman/live_dashboard_history",
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

  defp docs do
    [
      main: "LiveDashboardHistory",
      source_ref: "v#{@version}",
      source_url: "https://github.com/bglusman/live_dashboard_history",
      nest_modules_by_prefix: [LiveDashboardHistory]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      no_halt: "run --no-halt dev.exs",
      put_config: &put_config/1,
      dev: ["put_config", "no_halt"]
    ]
  end

  defp package do
    [
      maintainers: ["Brian Glusman"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/bglusman/live_dashboard_history"},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end

  defp put_config(_) do
    Application.put_env(:live_dashboard_history, LiveDashboardHistory,
      router: DemoWeb.Router,
      metrics: DemoWeb.Telemetry
    )
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_dashboard, "~> 0.2.7"},
      {:cbuf, "~> 0.7"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:norm, git: "https://github.com/keathley/norm.git", only: [:test]},
      {:stream_data, "~> 0.5", only: [:test]}
    ]
  end
end

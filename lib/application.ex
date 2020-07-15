defmodule LiveDashboardHistory.Application do
  use Application

  alias LiveDashboardHistory.HistorySupervisor

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Podder.Worker.start_link(arg)
      # {Podder.Worker, arg},
      {Registry, keys: :unique, name: LiveDashboardHistory.Registry},
      %{
        id: HistorySupervisor,
        start: {HistorySupervisor, :start_link, []}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveDashboardHistory.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

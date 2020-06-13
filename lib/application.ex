defmodule LiveDashboardHistory.Application do
  use Application

  alias LiveDashboardHistory.HistorySupervisor

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Podder.Worker.start_link(arg)
      # {Podder.Worker, arg},
      %{
        id: HistorySupervisor,
        start: {HistorySupervisor, :start_link, []}
      },
      {Registry, keys: :unique, name: LiveDashboardHistory.Registry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveDashboardHistory.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

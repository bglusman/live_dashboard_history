defmodule LiveDashboardHistory.HistorySupervisor do
  use DynamicSupervisor
  require Logger

  @default_buffer_size 50

  def start_link() do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    config = Application.get_env(:live_dashboard_history, LiveDashboardHistory)

    # sample_config =
    #   config
    #   |> List.wrap()
    #   |> List.first()

    # is_nil(sample_config) or !sample_config[:router] or !sample_config[:metrics] do
    if false do
      Logger.warn("WARNING: router and metrics configuration required for live_dashboard_history")
    else
      for %{
            router: router_module,
            metrics: metrics,
            buffer_size: buffer_size,
            skip_metrics: skip_metrics
          } <- normalize_config(config) do
        history_metrics = get_metrics(metrics) -- skip_metrics
        start_child(history_metrics, buffer_size, router_module)
      end

      {:ok, pid}
    end
  end

  defp get_metrics(metrics) when is_atom(metrics), do: apply(metrics, :metrics, [])

  defp get_metrics({metrics, function}) when is_atom(metrics) and is_atom(function),
    do: apply(metrics, function, [])

  defp normalize_config([{:router, router} | rest]) do
    [
      %{
        router: router,
        metrics: Keyword.fetch!(rest, :metrics),
        buffer_size: Keyword.get(rest, :buffer_size, @default_buffer_size),
        skip_metrics: Keyword.get(rest, :skip_metrics, [])
      }
    ]
  end

  defp normalize_config([%{router: router, metrics: metrics} = current_config | rest_configs]) do
    list_item = fn ->
      %{
        router: router,
        metrics: metrics,
        buffer_size: Map.get(current_config, :buffer_size, @default_buffer_size),
        skip_metrics: Map.get(current_config, :skip_metrics, [])
      }
    end

    case rest_configs do
      [] ->
        [list_item.()]

      non_empty_configs ->
        [list_item.() | normalize_config(non_empty_configs)]
    end
  end

  defp start_child(metrics, buffer_size, router_module) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {LiveDashboardHistory, [metrics, buffer_size, router_module]}
    )
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

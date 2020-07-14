defmodule LiveDashboardHistory.HistorySupervisor do
  use DynamicSupervisor
  require Logger

  @default_buffer_size 50
  @default_buffer_type Cbuf.Queue
  @env Mix.env()

  def start_link() do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    config = Application.get_env(:live_dashboard_history, LiveDashboardHistory)

    with {:ok, raw_config} <- config_state(config),
         map_list_config <- normalize_config(raw_config) do
      for %{
            router: router_module,
            metrics: metrics,
            buffer_size: buffer_size,
            buffer_type: buffer_type,
            skip_metrics: skip_metrics
          } <- map_list_config do
        history_metrics = get_metrics(metrics) -- skip_metrics
        start_child(history_metrics, buffer_size, buffer_type, router_module)
      end
    else
      {:error, :bad_config} ->
        unless @env == :test do
          Logger.warn(
            "WARNING: router and metrics config must be present for live_dashboard_history, router first if using keyword list"
          )
        end

      {:error, :no_config} ->
        unless @env == :test do
          Logger.warn(
            "WARNING: router and metrics configuration required for live_dashboard_history"
          )
        end
    end

    {:ok, pid}
  end

  def config_state(config) do
    case config do
      nil -> {:error, :no_config}
      [tuple | _] when is_tuple(tuple) -> validate(config, :tuple)
      [map | _] when is_map(map) -> validate(config, :map)
      _ -> {:error, :bad_config}
    end
  end

  def validate(config, :tuple) do
    if Keyword.has_key?(config, :router) and Keyword.has_key?(config, :metrics) do
      {:ok, config}
    else
      {:error, :bad_config}
    end
  end

  def validate(config, :map) do
    if Enum.all?(config, fn map -> Map.has_key?(map, :router) and Map.has_key?(map, :metrics) end) do
      {:ok, config}
    else
      {:error, :bad_config}
    end
  end

  defp get_metrics(metrics) when is_atom(metrics), do: apply(metrics, :metrics, [])

  defp get_metrics({metrics, function}) when is_atom(metrics) and is_atom(function),
    do: apply(metrics, function, [])

  defp get_metrics(metrics_fn) when is_function(metrics_fn),
    do: metrics_fn.()

  defp normalize_config([tuple | _rest] = config) when is_tuple(tuple) do
    [
      %{
        router: Keyword.fetch!(config, :router),
        metrics: Keyword.fetch!(config, :metrics),
        buffer_size: Keyword.get(config, :buffer_size, @default_buffer_size),
        buffer_type: Keyword.get(config, :buffer_type, @default_buffer_type),
        skip_metrics: Keyword.get(config, :skip_metrics, [])
      }
    ]
  end

  defp normalize_config([%{router: router, metrics: metrics} = current_config | rest_configs]) do
    list_item = fn ->
      %{
        router: router,
        metrics: metrics,
        buffer_size: Map.get(current_config, :buffer_size, @default_buffer_size),
        buffer_type: Map.get(current_config, :buffer_type, @default_buffer_type),
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

  def start_child(metrics, buffer_size, buffer_type, router_module) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {LiveDashboardHistory, [metrics, buffer_size, buffer_type, router_module]}
    )
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

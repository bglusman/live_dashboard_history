defmodule LiveDashboardHistory do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use GenServer
  alias Phoenix.LiveDashboard.TelemetryListener

  def metrics_history(metric, router_module) do
    case process_id(router_module) do
      nil -> []
      pid -> GenServer.call(pid, {:data, metric})
    end
  end

  def start_link([metrics, buffer_size, buffer_type, router_module]) do
    {:ok, pid} =
      GenServer.start_link(__MODULE__, [metrics, buffer_size, buffer_type, router_module])

    Registry.register(LiveDashboardHistory.Registry, router_module, pid)
    {:ok, pid}
  end

  defp process_id(router_module) do
    case Registry.lookup(LiveDashboardHistory.Registry, router_module) do
      [{_supervisor_pid, child_pid}] -> child_pid
      [] -> nil
    end
  end

  def init([metrics, buffer_size, buffer_type, router_module]) do
    GenServer.cast(self(), {:metrics, metrics, buffer_size, buffer_type, router_module})
    {:ok, %{}}
  end

  defp attach_handler(%{name: name_list} = metric, id, router_module) do
    :telemetry.attach(
      "#{inspect(name_list)}-history-#{id}-#{inspect(self())}",
      event(name_list),
      &__MODULE__.handle_event/4,
      {metric, router_module}
    )
  end

  defp event(name_list) do
    Enum.slice(name_list, 0, length(name_list) - 1)
  end

  def handle_event(_event_name, data, metadata, {metric, router_module}) do
    if data = TelemetryListener.prepare_entry(metric, data, metadata) do
      case process_id(router_module) do
        nil ->
          :noop

        pid ->
          GenServer.cast(pid, {:telemetry_metric, data, metric})
      end
    end
  end

  def handle_cast({:metrics, metrics, buffer_size, buffer_type, router_module}, _state) do
    metric_histories_map =
      metrics
      |> Enum.with_index()
      |> Enum.map(fn {metric, id} ->
        attach_handler(metric, id, router_module)
        {metric, buffer_type.new(buffer_size)}
      end)
      |> Map.new()

    {:noreply, {buffer_type, metric_histories_map}}
  end

  def handle_cast({:telemetry_metric, data, metric}, {buffer_type, state}) do
    {:noreply, {buffer_type, update_in(state[metric], &buffer_type.insert(&1, data))}}
  end

  def handle_call({:data, metric}, _from, {buffer_type, state}) do
    if history = state[metric] do
      {:reply, buffer_type.to_list(history), {buffer_type, state}}
    else
      {:reply, [], {buffer_type, state}}
    end
  end
end

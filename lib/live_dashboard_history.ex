defmodule LiveDashboardHistory do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use GenServer
  alias Phoenix.LiveDashboard.TelemetryListener

  def data(metric, router_module) do
    GenServer.call(process_name(router_module), {:data, metric})
  end

  def start_link([metrics, buffer_size, router_module]) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [metrics, buffer_size, router_module])
    Process.register(pid, process_name(router_module))
    {:ok, pid}
  end

  defp process_name(router_module), do: :"#{router_module}History"

  def init([metrics, buffer_size, router_module]) do
    GenServer.cast(self(), {:metrics, metrics, buffer_size, router_module})
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

  def handle_event(event_name, data, metadata, {metric, router_module}) do
    GenServer.cast(
      process_name(router_module),
      {:telemetry_metric, event_name, data, metadata, metric}
    )
  end

  def handle_cast({:metrics, metrics, buffer_size, router_module}, _state) do
    {:noreply,
     for metric <- metrics, reduce: %{} do
       acc ->
         key_metrics = Map.get(acc, event(metric.name), [])
         metric_map = %{metric: metric, history: CircularBuffer.new(buffer_size)}
         attach_handler(metric, length(key_metrics), router_module)

         Map.merge(acc, %{event(metric.name) => [metric_map | key_metrics]})
     end}
  end

  def handle_cast({:telemetry_metric, event_name, data, metadata, metric}, state) do
    if histories_list = state[event_name] do
      time = System.system_time(:microsecond)

      {%{history: history}, index} =
        histories_list
        |> Enum.with_index()
        |> Enum.find(fn {map, _index} -> map.metric == metric end)

      measurement = TelemetryListener.extract_measurement(metric, data)
      label = TelemetryListener.tags_to_label(metric, metadata)

      new_history =
        CircularBuffer.insert(history, %{label: label, measurement: measurement, time: time})

      new_histories_list =
        List.replace_at(histories_list, index, %{metric: metric, history: new_history})

      {:noreply, %{state | event_name => new_histories_list}}
    else
      {:noreply, state}
    end
  end

  def handle_call({:data, metric}, _from, state) do
    if metric_map = state[event(metric.name)] do
      %{history: history} = Enum.find(metric_map, &(&1.metric == metric))
      {:reply, CircularBuffer.to_list(history), state}
    else
      {:reply, [], state}
    end
  end
end

defmodule LiveDashboardHistoryTest do
  use ExUnit.Case, async: false
  import ExUnitProperties, only: [check: 2, property: 2]

  import Norm

  @cast_sleep_length 5
  property "events are recorded" do
    telemetry_schema =
      schema(%{
        name: coll_of(spec(is_atom()), min_count: 2, max_count: 5),
        measurement: map_of(spec(is_atom()), spec(is_number()), min_count: 1, max_count: 3)
      })

    metric_spec = one_of([:counter, :sum, :last_value, :summary, :distribution])

    buffer_type = one_of([Cbuf.Queue, Cbuf.ETS, Cbuf.Map])

    check all telemetry <- gen(telemetry_schema),
              metric_fn <- gen(metric_spec),
              buffer <- gen(buffer_type),
              # at the moment runs are parallel and can't support that yet
              max_runs: 1 do
      measures = Map.keys(telemetry.measurement)

      metrics =
        Enum.map(measures, fn measure ->
          apply(Telemetry.Metrics, metric_fn, ["#{Enum.join(telemetry.name, ".")}.#{measure}"])
        end)

      Application.put_env(:live_dashboard_history, LiveDashboardHistory,
        router: :router,
        metrics: fn -> metrics end,
        buffer_type: buffer
      )

      {:ok, pid} = LiveDashboardHistory.HistorySupervisor.start_link()
      # allow time for handle_cast({:metrics, ...})
      Process.sleep(@cast_sleep_length)
      :telemetry.execute(telemetry.name, telemetry.measurement, %{})
      # allow time for handle_cast({:telemetry_metric, ...})
      Process.sleep(@cast_sleep_length)

      Enum.map(metrics, fn metric ->
        assert LiveDashboardHistory.metrics_history(metric, :router) != []
      end)

      Process.exit(pid, :kill)
    end
  end
end

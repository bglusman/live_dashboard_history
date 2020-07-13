# LiveDashboardHistory

<!-- MDOC !-->
Storage and integration layer to add recent metrics history on each client connection to Phoenix LiveDashboard

![](https://github.com/bglusman/live_dashboard_history/workflows/CI/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/live_dashboard_history.svg)]()

LiveDashboard provides real-time performance monitoring and debugging tools for Phoenix developers. [See their docs here](https://hexdocs.pm/phoenix_live_dashboard)
for details on using and configuring it in general, but if you're using it or know how, and want to have recent history for metrics charts, this library provides an ephemeral storage mechanism and integration with (a fork of, for now) Phoenix LiveDashboard.  (once the fork, which provides a hook to allow providing history, is merged and released via Hex.pm, this library should be updated to not rely on fork and to work with any version of LiveDashboard after that.  Until then, this library relies on the fork and you should remove or comment any explicit dependency on `phoenix_live_dashboard` in your `mix.exs` and only rely on this library).


## Installation

The package can be installed via hex.pm by adding `live_dashboard_history` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_dashboard_history, "~> 0.1.0"}
  ]
end
```

## Configuration

Only two pieces of configuration are needed; first, in each router you wish to expose live_dashboard, follow the normal guidelines for configuration like so:

```elixir
live_dashboard "/dashboard",
    metrics: MyAppWeb.Telemetry,
    metrics_history: {LiveDashboardHistory, :metrics_history, [__MODULE__]}
```
(you may also pass in `:env_keys` and/or `:live_socket_path` config if you wish, but `:metrics` and `:metrics_history` are the minimum config that make sense with this library)

Assuming you only have one router in your Phoenix app (or only one you want to expose LiveDashboard with history in), you can then add config into your `config.exs` like so:
```
  config :live_dashboard_history, LiveDashboardHistory,
    router: MyAppWeb.Router,
    metrics: MyAppWeb.Telemetry
```
The router argument must come before metrics in config (when using a keyword list), and must evaluate to the same module as `__MODULE__` in the router where live_dashboard is configured.

The metrics argument may match the metrics argument passed in live_dashboard configuration, a module as above, a tuple of `{module, function}`, or you may also pass an inline 0-arity anonymous function directly in config which must return metrics.

You may also pass optional arguments `:buffer_size`, `:buffer_type` and/or `:skip_metrics`

* `buffer_size` defaults to 50
* `buffer_type` defaults to  `Cbuf.Queue` 
* `skip_metrics` defaults to `[]`
  
`:buffer_size` configures how many of each telemetry event are saved for each metric.  

`:buffer_type` is the module used for inserting chart data and transforming current state back to a list.  It should implement the [Cbuf behavior](https://hexdocs.pm/cbuf/Cbuf.html) in theory, though in practice all that matters is that it implements `new/1`, `insert/2` and `to_list/1`.  `new/1` will recieve the buffer size specified above, and insert will receive each chart data point prepared as a map.  If you wished to store all chart data in Redis, for example, you could implement a module that does this, and returns as much data for each entry on `to_list/2` as desired based on your own logic, disregarding buffer_size.

`:skip_metrics` allows you to save memory by filtering out metrics you don't care to have history available on in LiveDashboard.  You may also just use a different metrics function than the one passed to live_dashboard config that returns only the metrics for which you wish to retain history.

If you have multiple Routers and wish to expose LiveDashboard in each of them, you may pass in a list of maps instead of using a Keyword list as above, e.g.

```
  config :live_dashboard_history, LiveDashboardHistory, [
    %{
      router: MyAppWeb.Router1,
      metrics: MyAppWeb.Telemetry1
    },
    %{
      router: MyAppWeb.Router2,
      metrics: MyAppWeb.Telemetry2},
    }
  ]
```
Each map may also have the optional keys `:buffer_size`, `:buffer_type` and `:skip_metrics`, and each metrics key may take any of the values outlines above.
<!-- MDOC !-->

## Contributing

For those planning to contribute to this project, you can run a dev version of the dashboard with the following commands:

    $ mix setup
    $ mix dev

Alternatively, run `iex -S mix dev` if you also want a shell.

## License

MIT License. Copyright (c) 2020 Brian Glusman.


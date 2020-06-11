# LiveDashboardHistory

<!-- MDOC !-->
Storage and integration layer to add recent history to Phoenix LiveDashboard

LiveDashboard provides real-time performance monitoring and debugging tools for Phoenix developers. [See their docs here](https://hexdocs.pm/phoenix_live_dashboard)
for details on using and configuring it in general, but if you're using it or know how, and want to have recent history for metrics charts, this library provides an ephemeral storage mechanism and integration with (a fork of, for now) Phoenix LiveDashboard.  (once the fork, which provides a hook to allow providing history, is merged and released via Hex.pm, this library should be updated to not rely on fork and to work with any version of LiveDashboard after that.  Until then, this library relies on the fork and you should remove or comment any explicit dependency on `phoenix_live_dashboard` in your `mix.exs` and only rely on this library).


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `live_dashboard_history` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_dashboard_history, "~> 0.1.0"}
  ]
end
```

## Configuration

Only two pieces of configuration are needed;  First, in each router you wish to expose live_dashboard, follow the normal guidelines for configuration like so:

```elixir
live_dashboard "/dashboard",
    metrics: MyAppWeb.Telemetry,
    historical_data: {LiveDashboardHistory, :data, [__MODULE__]}
```

Assuming you only have one router in your Phoenix app (or only one you want to expose LiveDashboard with history in), you can then add config into your `config.exs` like so:
```
  config :live_dashboard_history, LiveDashboardHistory,
    router: MyAppWeb.Router,
    metrics: MyAppWeb.Telemetry
```

You may also pass optional arguments `:buffer_size` and/or `:skip_metrics`;  they dedault to 50 and `[]`.  `:buffer_size` configures how many of each telemetry event are saved for each metric. `:skip_metrics` allows you to save memory by filtering out metrics you don't care to have history available on in LiveDashboard.

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
Each map may also have the optional keys `:buffer_size` and `:skip_metrics`
<!-- MDOC !-->

## Contributing

For those planning to contribute to this project, you can run a dev version of the dashboard with the following commands:

    $ mix setup
    $ mix dev

Alternatively, run `iex -S mix dev` if you also want a shell.

## License

MIT License. Copyright (c) 2020 Brian Glusman.


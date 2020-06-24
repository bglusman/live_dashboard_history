Application.load(:live_dashboard_history)
Application.ensure_all_started(:stream_data)
Application.ensure_all_started(:telemetry)
ExUnit.start()

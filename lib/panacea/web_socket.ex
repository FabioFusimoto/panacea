defmodule Panacea.WebSocket do
  use WebSockex
  require Logger

  @ip_address "192.168.0.9"
  @acknowledgement_timeout 400
  @log_period 2500

  #############
  # Interface #
  #############
  def start_link(_opts) do
    {:ok, pid} = WebSockex.start_link(
      "ws://" <> @ip_address,
      __MODULE__,
      %{
        waiting_line: %{},
        success_count: 0,
        failure_count: 0,
        should_log?: false,
        time_waiting_for_responses: 0
      },
      name: __MODULE__
    )

    logger_loop()

    {:ok, pid}
  end

  def send(message) do
    WebSockex.send_frame(__MODULE__, {:text, message})

    started_at = :os.system_time(:millisecond)
    success? = wait_for_acknowledgement(message)
    finished_at = :os.system_time(:millisecond)

    WebSockex.cast(__MODULE__, {:update_statistics, success?, finished_at - started_at})
  end

  ############
  # Handlers #
  ############

  # WebSockex related
  def handle_connect(_conn, state) do
    {:ok, state}
  end

  def handle_frame({:text, message}, state) do
    waiting_process = state.waiting_line[message]

    if waiting_process do
      send(waiting_process, {:ack, message})
    end

    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, _reason}}, state) do
    {:ok, state}
  end
  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end

  # "Regular" handlers
  def handle_cast({:update_waiting_line, message, pid}, state) do
    new_waiting_line = Map.put(state.waiting_line, message, pid)
    {:ok, Map.put(state, :waiting_line, new_waiting_line)}
  end

  def handle_cast({:update_statistics, success?, time_elapsed_for_last_command}, state) do
    time_elapsed_so_far = state.time_waiting_for_responses
    partial_new_state = %{
      state |
      time_waiting_for_responses: time_elapsed_so_far + time_elapsed_for_last_command,
      should_log?: true
    }

    if success? do
      previous_success_count = state.success_count
      {:ok, %{partial_new_state | success_count: previous_success_count + 1}}
    else
      previous_failure_count = state.failure_count
      {:ok, %{partial_new_state | failure_count: previous_failure_count + 1}}
    end
  end

  def handle_info(:log_statistics, state) do
    if state.should_log? do
      sc = state.success_count
      fc = state.failure_count
      failure_ratio_percentage = fc / (fc + sc) * 100
      |> Float.round(2)
      |> Float.to_string()

      average_response_time = state.time_waiting_for_responses / (sc + fc)
      |> Float.round(2)
      |> Float.to_string()

      IO.puts(
        "Success: #{sc} \n" <>
        "Failure: #{fc} \n" <>
        "Failure Ratio: #{fc} / #{fc + sc} (#{failure_ratio_percentage}%) \n" <>
        "Average command response time: #{average_response_time} ms\n"
      )
    end

    logger_loop()

    {:ok, Map.put(state, :should_log?, false)}
  end

  ###########
  # Helpers #
  ###########
  defp wait_for_acknowledgement(message) do
    pid = self()
    WebSockex.cast(__MODULE__, {:update_waiting_line, message, pid})

    receive do
      {:ack, ^message} -> true
    after
      @acknowledgement_timeout -> false
    end
  end

  defp logger_loop(), do: Process.send_after(__MODULE__, :log_statistics, @log_period)
end

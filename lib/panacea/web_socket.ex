defmodule Panacea.WebSocket do
  use WebSockex
  require Logger

  @ip_address "192.168.0.9"
  @acknowledgement_timeout 800

  #############
  # Interface #
  #############
  def start_link(_opts) do
    WebSockex.start_link("ws://" <> @ip_address, __MODULE__, %{waiting_line: %{}}, name: __MODULE__)
  end

  def send(message) do
    # IO.puts("[#{DateTime.utc_now()}] #{message}")
    WebSockex.send_frame(__MODULE__, {:text, message})
    wait_for_acknowledgement(message)
  end

  ############
  # Handlers #
  ############
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

  def handle_cast({:update_waiting_line, message, pid}, state) do
    new_waiting_line = Map.put(state.waiting_line, message, pid)
    {:ok, Map.put(state, :waiting_line, new_waiting_line)}
  end

  def handle_disconnect(%{reason: {:local, _reason}}, state) do
    {:ok, state}
  end
  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end

  ###########
  # Helpers #
  ###########
  defp wait_for_acknowledgement(message) do
    pid = self()
    WebSockex.cast(__MODULE__, {:update_waiting_line, message, pid})
    receive do
      {:ack, ^message} -> :ok
    after
      @acknowledgement_timeout -> IO.puts("Acknowledge timeout for message: #{message}")
    end
  end
end

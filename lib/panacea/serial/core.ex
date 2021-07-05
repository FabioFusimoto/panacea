defmodule Panacea.Serial.Core do
  use Agent
  alias Circuits.UART, as: Serial

  @agent :serial_connection
  @port "ttyUSB0"
  @baud_rate 115_200

  def start_link(_args) do
    Agent.start_link(fn -> connect() end, name: @agent)
  end

  def connect() do
    {:ok, connection} = Serial.start_link()
    Serial.open(connection, @port, speed: @baud_rate, active: false)
    connection
  end

  def retrieve_connection() do
    Agent.get(@agent, fn connection -> connection end, 1000)
  end
end

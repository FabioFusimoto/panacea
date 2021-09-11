defmodule Panacea.Serial do
  use GenServer
  alias Circuits.UART, as: Serial

  @port "ttyUSB0"
  @baud_rate 115_200

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, connection} = Serial.start_link()
    Serial.open(connection, @port, speed: @baud_rate, active: false)
    {:ok, %{connection: connection}}
  end

  def retrieve_connection() do
    GenServer.call(__MODULE__, {:retrieve_connection})
  end

  def handle_call({:retrieve_connection}, _, %{connection: connection}) do
    {:reply, connection, %{connection: connection}}
  end
end

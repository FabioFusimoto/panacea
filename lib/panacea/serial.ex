defmodule Panacea.Serial do
  use GenServer
  alias Circuits.UART, as: Serial

  @baud_rate 115_200

  #############
  # Interface #
  #############
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def retrieve_connection() do
    GenServer.call(__MODULE__, :retrieve_connection)
  end

  def init(_) do
    {:ok, connection} = Serial.start_link()
    Serial.open(connection, port_to_use(), speed: @baud_rate, active: false)
    {:ok, %{connection: connection}}
  end

  ############
  # Handlers #
  ############
  def handle_call(:retrieve_connection, _, %{connection: connection}) do
    {:reply, connection, %{connection: connection}}
  end

  ###########
  # Helpers #
  ###########
  defp port_to_use() do
    Serial.enumerate()
    |> Enum.find(fn {_, device} -> device[:product_id] && device[:vendor_id] end)
    |> elem(0)
  end
end

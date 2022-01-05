defmodule Panacea.Serial do
  use GenServer
  alias Circuits.UART, as: Serial

  @baud_rate 921_600
  @acknowledge "*"
  @response_timeout 500

  #############
  # Interface #
  #############
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, connection} = Serial.start_link()
    Serial.open(connection, port_to_use(), speed: @baud_rate, active: false)

    # Exaust all characters currently on the serial buffer before starting
    {:ok, _} = read(connection)

    {:ok, %{connection: connection}}
  end

  def write(message) do
    connection = retrieve_connection()
    Serial.write(connection, message)

    # Waiting for an acknowledge signal
    {:ok, @acknowledge} = read(connection)
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
  def port_to_use() do
    Serial.enumerate()
    |> IO.inspect()
    |> Enum.find(fn {_, device} -> device[:product_id] && device[:vendor_id] end)
    |> elem(0)
    |> IO.inspect()
  end

  def retrieve_connection() do
    GenServer.call(__MODULE__, :retrieve_connection)
  end

  def read(connection) do
    Serial.read(connection, @response_timeout)
  end
end

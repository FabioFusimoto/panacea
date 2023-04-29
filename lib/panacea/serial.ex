defmodule Panacea.Serial do
  use WebSockex

  @ip_address "localhost:8001"

  #############
  # Interface #
  #############
  def start_link(_) do
    try do
      connect()
    rescue
      _ ->
        IO.puts("Serial server not running on #{@ip_address}. Starting it...")
        {_, os_type} = :os.type()

        python_file =
          case os_type do
            :linux ->
              "./priv/python/webSocketServerForSerialCommunication.py"
            _ ->
              ".\\priv\\python\\webSocketServerForSerialCommunication.py"
          end

        Task.start(
          fn ->
            System.cmd("python", [python_file])
          end
        )

        :timer.sleep(1000)

        connect()
    end
  end

  def write(message) do
    WebSockex.send_frame(__MODULE__, {:text, message})
  end

  defp connect() do
    {:ok, pid} = WebSockex.start_link(
      "ws://" <> @ip_address,
      __MODULE__,
      %{},
      name: __MODULE__
    )

    {:ok, pid}
  end
end

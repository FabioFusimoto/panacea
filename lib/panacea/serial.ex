defmodule Panacea.Serial do
  use WebSockex

  @ip_address "localhost:8001"

  #############
  # Interface #
  #############
  def start_link(_) do
    {:ok, pid} = WebSockex.start_link(
      "ws://" <> @ip_address,
      __MODULE__,
      %{},
      name: __MODULE__
    )
    {:ok, pid}
  end

  def write(message) do
    WebSockex.send_frame(__MODULE__, {:text, message})
  end
end

defmodule Panacea.BacklightingServer do
  use GenServer

  alias Panacea.Backlighting
  alias Panacea.Worker

  @refresh_timeout 25

  #############
  # Interface #
  #############
  def start() do
    stop()
    Worker.reset_if_running()
    GenServer.start(__MODULE__, %{}, name: __MODULE__)
  end

  def stop() do
    if Process.whereis(__MODULE__) do
      GenServer.stop(__MODULE__)
    end
  end

  def init(_) do
    # Automatically update its state in a loop
    loop(@refresh_timeout)
    {:ok, %{}}
  end

  def handle_info(:update_backlighting, state) do
    Backlighting.display_matching_color()
    loop(@refresh_timeout)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  ###########
  # Helpers #
  ###########
  defp loop(timeout), do: Process.send_after(self(), :update_backlighting, timeout)
end

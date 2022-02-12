defmodule PanaceaWeb.Monitor do
  use GenServer

  #############
  # Interface #
  #############
  def monitor(pid, view_module) do
    GenServer.call(
      __MODULE__,
      {:monitor, pid, view_module}
    )
  end

  ##################
  # Initialization #
  ##################
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  ############
  # Handlers #
  ############
  def handle_call({:monitor, pid, view_module}, _, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, view_module)}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    IO.puts(":DOWN #{inspect(pid)}")

    {view_module, new_views} = Map.pop(state.views, pid)
    view_module.unmount()

    new_state = %{state | views: new_views}
    {:noreply, new_state}
  end
end

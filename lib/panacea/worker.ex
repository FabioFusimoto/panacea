defmodule Panacea.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{current_task: nil}}
  end

  def execute(task) do
    GenServer.cast(__MODULE__, {:execute, task})
  end

  def reset_if_running() do
    GenServer.call(__MODULE__, {:clear})
  end

  def handle_cast({:execute, task}, %{current_task: current_task}) do
    kill_current_task(current_task)

    {:ok, task_pid} = Task.start(
      fn ->
        task.()
        :cleared = GenServer.call(__MODULE__, {:clear})
      end
    )

    {:noreply, %{current_task: task_pid}}
  end

  def handle_call({:clear}, _, %{current_task: current_task}) do
    kill_current_task(current_task)
    {:reply, :cleared, %{current_task: nil}}
  end

  defp kill_current_task(current_task) do
    if current_task do
      Process.exit(current_task, :kill)
    end
  end

end

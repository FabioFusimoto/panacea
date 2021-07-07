defmodule Panacea.Worker do
  use Agent

  # This :worker Agent is supposed to store the pid for the proccess it's currently
  # executing; or nil if it's not executing anything
  @agent :worker

  def start_link(_args) do
    Agent.start_link(fn -> nil end, name: @agent)
  end

  def execute(task) do
    reset_if_running()

    {:ok, new_pid} = Task.start(
      fn ->
        task.()
        Agent.update(@agent, fn _current_pid -> nil end)
      end
    )

    Agent.update(@agent, fn _current_pid -> new_pid end)
  end

  def reset_if_running() do
    current_pid = Agent.get(@agent, fn pid -> pid end)

    if current_pid do
      Process.exit(current_pid, :kill)
    end
  end
end

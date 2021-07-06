defmodule Panacea.Worker do
  use Agent

  # This :worker Agent is supposed to store the pid for the proccess it's currently
  # executing; or nil if it's not executing anything
  @agent :worker

  def start_link(_args) do
    Agent.start_link(fn -> nil end, name: @agent)
  end

  def execute(task) do
    current_pid = Agent.get(@agent, fn pid -> pid end)

    if current_pid do
      Process.exit(current_pid, :kill)
    end

    {:ok, new_pid} = Task.start(
      fn ->
        Process.sleep(3000)
        task.()
        Agent.update(@agent, fn _current_pid -> nil end)
      end
    )

    Agent.update(@agent, fn _current_pid -> new_pid end)
  end
end

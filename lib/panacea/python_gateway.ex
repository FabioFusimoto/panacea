defmodule Panacea.PythonGateway do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    path = Path.join([:code.priv_dir(:panacea), "python"])

    with {:ok, instance} <- :python.start([{:python_path, to_charlist(path)}, {:python, 'python'}]) do
      IO.inspect("[#{__MODULE__}] Started python gateway")
      IO.inspect(instance)
      {:ok, %{instance: instance}}
    end
  end

  def call_python(file, function, args) do
    GenServer.call(
      __MODULE__,
      {:call_python, file, function, args}
    )
  end

  def handle_call({:call_python, file, function, args}, _, %{instance: instance}) do
    result = :python.call(instance, file, function, args)
    {:reply, result, %{instance: instance}}
  end
end

defmodule Panacea.PythonGateway do
  use GenServer
  require Logger

  @module_alias :python_gateway
  @timeout 5000

  def poolboy_config() do
    [
      name: {:local, @module_alias},
      worker_module: Panacea.PythonGateway,
      size: 2,
      max_overflow: 0
    ]
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    path = Path.join([:code.priv_dir(:panacea), "python"])

    with {:ok, instance} <- :python.start([{:python_path, to_charlist(path)}, {:python, 'python'}]) do
      {:ok, %{instance: instance}}
    end
  end

  def call_python(file, function, args) do
    Task.async(
      fn ->
        :poolboy.transaction(
          @module_alias,
          fn pid ->
            GenServer.call(
              pid,
              {:call_python, file, function, args}
            )
          end,
          @timeout
        )
      end
    )
    |> Task.await(@timeout)
  end

  def handle_call({:call_python, file, function, args}, _, %{instance: instance}) do
    result = :python.call(instance, file, function, args)
    {:reply, result, %{instance: instance}}
  end
end

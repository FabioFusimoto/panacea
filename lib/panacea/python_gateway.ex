defmodule Panacea.PythonGateway do
  use GenServer
  require Logger

  @module_alias :python_gateway
  @timeout 15000

  ##################
  # Initialization #
  ##################
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    path = Path.join([:code.priv_dir(:panacea), "python"])

    with {:ok, instance} <- :python.start([{:python_path, to_charlist(path)}, {:python, 'python'}]) do
      {:ok, %{instance: instance}}
    end
  end

  #############
  # Interface #
  #############
  def list_devices(type) do
    devices = call_python(:audio, :devices, [])
    filter_fn = fn device ->
      if type == :input do
        device['maxInputChannels'] > 0
      else
        device['maxOutputChannels'] > 0
      end
    end
    Enum.filter(devices, filter_fn)
  end

  def record(device_index, duration) do
    call_python(:audio, :record, [device_index, duration])
  end

  ############
  # Handlers #
  ############
  def handle_call({:call_python, file, function, args}, _, %{instance: instance}) do
    result = :python.call(instance, file, function, args)
    {:reply, result, %{instance: instance}}
  end

  ###########
  # Helpers #
  ###########
  def poolboy_config() do
    [
      name: {:local, @module_alias},
      worker_module: Panacea.PythonGateway,
      size: 2,
      max_overflow: 0
    ]
  end

  defp call_python(file, function, args) do
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

end

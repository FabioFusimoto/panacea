defmodule Panacea.PythonGateway do
  use GenServer
  require Logger

  @module_alias :python_gateway
  @timeout 250

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
    call_result = call_python(:audio, :devices, [])

    case call_result do
      {:ok, device_descriptions} ->
        filter_fn = fn device ->
          if type == :input do
            device['maxInputChannels'] > 0
          else
            device['maxOutputChannels'] > 0
          end
        end
        Enum.filter(device_descriptions, filter_fn)
      :failed ->
        []
    end
  end

  def spectrum(device_index, duration, threshold_frequencies) do
    call_result = call_python(
      :audio,
      :spectrum,
      [device_index, duration, threshold_frequencies]
    )

    fallback = Enum.map(
      threshold_frequencies,
      fn f -> [f, 0] end
    )

    case call_result do
      {:ok, spectrum_analyzed} -> spectrum_analyzed
      :failed -> fallback
    end
  end

  ############
  # Handlers #
  ############
  def handle_call({:call_python, file, function, args}, _, %{instance: instance}) do
    result = :python.call(instance, file, function, args)
    {:reply, result, %{instance: instance}}
  end

  def handle_info(:timeout, state) do
    {:noreply, state}
  end

  ###########
  # Helpers #
  ###########
  def poolboy_config() do
    [
      name: {:local, @module_alias},
      worker_module: Panacea.PythonGateway,
      size: 100,
      max_overflow: 0
    ]
  end

  defp call_python(file, function, args) do
    python_call_task = Task.async(
      fn ->
        :poolboy.transaction(
          @module_alias,
          fn pid ->
            try do
              GenServer.call(
                pid,
                {:call_python, file, function, args}
              )
            catch
              :exit, _ -> :failed
            end
          end,
          @timeout
        )
      end
    )

    task_result = Task.yield(python_call_task, @timeout)

    case task_result do
      {:ok, result} ->
        {:ok, result}
      _ ->
        :failed
    end
  end
end

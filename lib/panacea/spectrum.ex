defmodule Panacea.Spectrum do
  use GenServer
  alias Phoenix.PubSub

  alias Panacea.PythonGateway

  @topic "live_spectrum"
  @threshold_frequencies [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

  #############
  # Interface #
  #############
  def start(device_index, update_rate) do
    update_interval = div(1000, update_rate)

    GenServer.start(
      __MODULE__,
      %{
        device_index: device_index,
        update_interval: update_interval,
        normalization: %{
          constant: 100,
          iterations_since_last_update: 0
        }
      },
      name: __MODULE__
    )
  end

  def stop() do
    if running?() do
      GenServer.stop(__MODULE__)
    end
  end

  #################
  # Initilization #
  #################
  def init(state) do
    Process.send_after(self(), :update_spectrum, state.update_interval)
    {:ok, state}
  end

  ############
  # Handlers #
  ############
  def handle_info(:update_spectrum, state) do
    %{
      device_index: device_index,
      update_interval: update_interval,
      normalization: %{
        constant: constant,
        iterations_since_last_update: iterations_since_constant_update,
      }
    } = state

    spectrum = PythonGateway.spectrum(
      device_index,
      update_interval,
      @threshold_frequencies,
      constant
    )

    max_spectrum_power = max_spectrum_power(spectrum)
    {next_normalization_constant, iterations_since_constant_update} =
      if update_normalization_constant?(max_spectrum_power, constant, iterations_since_constant_update) do
        {max_spectrum_power, 0}
      else
        {constant, iterations_since_constant_update + 1}
      end

    PubSub.broadcast(
      Panacea.PubSub,
      @topic,
      %{
        topic: @topic,
        payload: %{
          spectrum: normalize(next_normalization_constant, spectrum)
        }
      }
    )

    Process.send(self(), :update_spectrum, [])

    {
      :noreply,
      %{
        state |
        normalization: %{
          constant: next_normalization_constant,
          iterations_since_last_update: iterations_since_constant_update,
        }
      }
    }
  end

  ###########
  # Helpers #
  ###########
  defp running?(), do: Process.whereis(__MODULE__)

  defp max_spectrum_power(spectrum) do
    Enum.max(for [_, p] <- spectrum do p end)
  end

  defp normalize(normalization_constant, spectrum) do
    for [f, p] <- spectrum do
      try do
        [f, Enum.min([18, round(p * 18 / normalization_constant)])]
      catch
        _ -> [f, 0]
      end
    end
  end

  defp update_normalization_constant?(new, old, iterations), do: new > old or iterations > 50
end

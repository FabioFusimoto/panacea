defmodule Panacea.Spectrum.Displayer do
  use GenServer
  alias Phoenix.PubSub

  alias Panacea.Spectrum.Commons
  alias Panacea.Commands
  alias Panacea.Leds

  @topic       "live_spectrum"
  @lit_colors  [
    [  0, 255, 0],
    [  0, 255, 0],
    [ 36, 255, 0],
    [ 72, 255, 0],
    [109, 255, 0],
    [145, 255, 0],
    [182, 255, 0],
    [218, 255, 0],
    [255, 255, 0],
    [255, 255, 0],
    [255, 218, 0],
    [255, 182, 0],
    [255, 145, 0],
    [255, 109, 0],
    [255,  72, 0],
    [255,  36, 0],
    [255,   0, 0],
    [255,   0, 0]
  ]
  @unlit_color [0, 0, 0]
  @max_power   18
  @x_offset    4

  #############
  # Interface #
  #############
  def start(init_params \\ %{}) do
    GenServer.start(__MODULE__, init_params, name: __MODULE__)
  end

  def stop() do
    if Process.whereis(__MODULE__) do
      GenServer.stop(__MODULE__)
    end
  end

  def init(init_params) do
    PubSub.subscribe(Panacea.PubSub, @topic)
    spectrum = Enum.map(
      Commons.frequencies(),
      fn f -> [f, 0] end
    )
    Leds.light_all(@unlit_color)
    {:ok, Map.put(init_params, :spectrum, spectrum)}
  end

  ############
  # Handlers #
  ############
  def handle_info(
    %{
      topic: @topic,
      payload: %{
        spectrum: new_spectrum,
      }
    },
    state
  ) do
    new_spectrum_with_indexes = Enum.with_index(new_spectrum)
    previous_spectrum = state.spectrum

    spectrum_changes = Enum.filter(
      new_spectrum_with_indexes,
      fn {frequency_and_power, index} ->
        frequency_and_power != Enum.at(previous_spectrum, index)
      end
    )

    if Enum.count(spectrum_changes) > 0 do
      args = spectrum_changes
      |> Enum.map(
        fn {[_frequency, new_power], index} ->
          old_power = previous_spectrum |> Enum.at(index) |> Enum.at(1)

          if new_power > old_power do
            for y <- old_power..(new_power - 1) do
              [index + @x_offset, @max_power - 1 - y] ++ Enum.at(@lit_colors, y)
            end
          else
            for y <- new_power..(old_power - 1) do
              [index + @x_offset, @max_power - 1 - y] ++ @unlit_color
            end
          end
        end
      )
      |> Enum.reduce(fn args, acc -> acc ++ args end)

      commands = for _ <- args do "ONE" end

      Commands.write_multiple!(
        List.insert_at(commands, -1, "SHO"),
        List.insert_at(args, -1, [])
      )
    end

    {:noreply, Map.put(state, :spectrum, new_spectrum)}
  end
end

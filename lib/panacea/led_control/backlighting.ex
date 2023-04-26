defmodule Panacea.Backlighting do
  alias ColorUtils

  alias Panacea.Colors
  alias Panacea.Commands
  alias Panacea.PythonGateway

  @led_count 62

  def display_gradient(starting_color_hex_string, ending_color_hex_string) do
    starting_rgb = Colors.hex_string_to_rgb_array(starting_color_hex_string)
    ending_rgb = Colors.hex_string_to_rgb_array(ending_color_hex_string)

    [r_delta, g_delta, b_delta] =
      starting_rgb
      |> Enum.zip(ending_rgb)
      |> Enum.map(fn {starting_value, ending_value} ->
        (ending_value - starting_value) / (@led_count - 1)
      end)

    [starting_r, starting_g, starting_b] = starting_rgb

    colors_sequence = 0..(@led_count - 1)
    |> Enum.map(fn index ->
      [
        index,
        round(starting_r + r_delta * index),
        round(starting_g + g_delta * index),
        round(starting_b + b_delta * index)
      ]
    end)
    |> Enum.map(fn [index | color] ->
      gamma_corrected_color = Colors.color_with_corrected_gamma(color)
      [index | gamma_corrected_color]
    end)

    display_one_commands = for(_ <- 1..@led_count, do: "ONB")

    Commands.write_multiple!(display_one_commands, colors_sequence)
    Commands.write!("SHO")
  end

  def display_matching_color() do
    result = PythonGateway.most_frequent_color()

    case result do
      {:ok, color_hex} ->
        original_rgb = Colors.hex_string_to_rgb_array(color_hex)
        gamma_corrected_color = Colors.color_with_corrected_gamma(original_rgb)
        Commands.write!("ALB", gamma_corrected_color)

      _ ->
        IO.puts("Couldn't retrieve matching color for screen!")
    end
  end
end

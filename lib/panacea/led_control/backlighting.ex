defmodule Panacea.Backlighting do
  alias Panacea.Commands, as: Commands

  @led_count 62

  @doc "Returns [r,g,b] as integers from a #HHHHHH hex string representation"
  defp hex_string_to_rgb_array(hex_string) do
    r_str = String.slice(hex_string, 1..2)
    g_str = String.slice(hex_string, 3..4)
    b_str = String.slice(hex_string, 5..6)

    {r, _} = Integer.parse(r_str, 16)
    {g, _} = Integer.parse(g_str, 16)
    {b, _} = Integer.parse(b_str, 16)

    [r, g, b]
  end

  def display_gradient(starting_color_hex_string, ending_color_hex_string) do
    starting_rgb = hex_string_to_rgb_array(starting_color_hex_string)
    ending_rgb = hex_string_to_rgb_array(ending_color_hex_string)

    [r_delta, g_delta, b_delta] =
      starting_rgb
      |> Enum.zip(ending_rgb)
      |> Enum.map(fn {starting_value, ending_value} ->
        (ending_value - starting_value) / (@led_count - 1)
      end)

    [starting_r, starting_g, starting_b] = starting_rgb

    colors_sequence =
      Enum.map(
        0..(@led_count - 1),
        fn index ->
          [
            index,
            round(starting_r + r_delta * index),
            round(starting_g + g_delta * index),
            round(starting_b + b_delta * index)
          ]
        end
      )

    display_one_commands = for(_ <- 1..@led_count, do: "ONB")

    Commands.write_multiple!(display_one_commands, colors_sequence)
    Commands.write!("SHO")
  end
end

defmodule Panacea.Colors do
  @default_saturation_boost 30

  alias ColorUtils

  defp rgb_struct_to_array(rgb) do
    [trunc(rgb.red), trunc(rgb.green), trunc(rgb.blue)]
  end

  def hex_string_to_rgb_array(hex_string) do
    hex_string = hex_string
    |> String.replace(~r/'/, "")
    |> String.upcase()

    rgb = ColorUtils.hex_to_rgb(hex_string)
    rgb_struct_to_array(rgb)
  end

  def with_saturation_boost(rgb_array, boost \\ @default_saturation_boost) do
    rgb_struct = %ColorUtils.RGB{
      red: Enum.at(rgb_array, 0),
      green: Enum.at(rgb_array, 1),
      blue: Enum.at(rgb_array, 2)
    }

    hsv = ColorUtils.rgb_to_hsv(rgb_struct)
    hsv_with_boosted_saturation = %{
      hsv |
      saturation: Enum.min([100, hsv.saturation + boost])
    }

    rgb_with_boosted_saturation = ColorUtils.hsv_to_rgb(hsv_with_boosted_saturation)
    rgb_struct_to_array(rgb_with_boosted_saturation)
  end
end

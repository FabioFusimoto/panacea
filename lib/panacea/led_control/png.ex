defmodule Panacea.Png do
  alias Imagineer, as: Png

  @height 18
  @width 18

  defp rgba_to_rgb({r, g, b, _}) do
    Tuple.to_list({r, g, b})
  end

  def read_image(filename) do
    {:ok, image} = Png.load(filename)
    Enum.map(image.pixels, fn row -> Enum.map(row, &rgba_to_rgb(&1)) end)
  end

  def color_for(frame, x, y), do: frame |> Enum.at(y) |> Enum.at(x)

  defp different_colors?(old, new, x, y) do
    color_for(old, x, y) != color_for(new, x, y)
  end

  defp frame_diff({old, new}) do
    for y <- 0..(@height - 1), x <- 0..(@width - 1), different_colors?(old, new, x, y) do
      {x, y}
    end
  end

  @doc """
  Assumes the GIF is generated by all files in the directory, and the sequence
  is defined by the files' names
  """
  def read_gif(directory) do
    files = Path.wildcard(directory <> "*.png")

    frames = Enum.map(files, fn image -> read_image(image) end)

    frame_count = length(frames)

    shifted_frames =
      frames
      |> List.insert_at(frame_count, Enum.at(frames, 0))
      |> List.delete_at(0)

    pixel_diff =
      frames
      |> Enum.zip(shifted_frames)
      |> Enum.map(&frame_diff/1)

    {shifted_frames, pixel_diff}
  end
end

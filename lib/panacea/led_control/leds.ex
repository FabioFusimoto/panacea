defmodule Panacea.Leds do
  alias Panacea.Colors
  alias Panacea.Commands
  alias Panacea.Png

  def show_leds() do
    Commands.write!("SHO")
  end

  def light_all(color) do
    gamma_corrected_color = Colors.color_with_corrected_gamma(color)
    Commands.write!("ALL", gamma_corrected_color)
  end

  def light_all_back(color) do
    gamma_corrected_color = Colors.color_with_corrected_gamma(color)
    Commands.write!("ALB", gamma_corrected_color)
  end

  def light_single(color, x, y) do
    gamma_corrected_color = Colors.color_with_corrected_gamma(color)
    Commands.write!("ONE", gamma_corrected_color |> List.insert_at(0, y) |> List.insert_at(0, x))
    :ok
  end

  def light_single_back(color, index) do
    gamma_corrected_color = Colors.color_with_corrected_gamma(color)
    Commands.write!("ONB", gamma_corrected_color |> List.insert_at(0, index))
    :ok
  end

  def light_matrix(frame, {x_offset, y_offset} \\ {0, 0}) do

    arg_list = for y <- 0..(length(frame) - 1), x <- 0..(length(Enum.at(frame, y)) - 1) do
      corrected_color = frame
      |> Png.color_for(x, y)
      |> Colors.color_with_corrected_gamma()

      [x + x_offset, y + y_offset] ++ corrected_color
    end

    one_commands = for _ <- 1..length(arg_list) do
      "ONE"
    end

    Commands.write_multiple!(one_commands, arg_list)
    show_leds()
  end

  def display_png(filename, offset \\ {0, 0}) do
    frame = Png.read_image(filename)
    light_matrix(frame, offset)
  end

  @doc """
  Displays a GIF made of all PNG on the provided directoty,
  ordered by the files' names. It will attempt to display the
  GIF at most at the provided target_fps. If the target_fps
  is 0, it will try to display it as fast as possible.
  """
  def display_gif(directory, target_fps, repetitions) do
    {shifted_frames, pixel_diff} = Png.read_gif(directory)
    light_matrix(List.last(shifted_frames))
    # in miliseconds
    target_frametime = round(1_000 / target_fps)

    for _ <- 1..repetitions do
      Enum.each(
        Enum.zip(shifted_frames, pixel_diff),
        fn {frame, diff} ->
          started_at = System.system_time(:millisecond)

          commands =
            for _ <- 1..length(diff) do
              "ONE"
            end
            |> List.insert_at(length(diff), "SHO")

          arg_list =
            diff
            |> Enum.map(
              fn {x, y} ->
                corrected_color = frame
                |> Png.color_for(x, y)
                |> Colors.color_with_corrected_gamma()

                [x, y] ++ corrected_color
              end)
            |> List.insert_at(length(diff), [])

          Commands.write_multiple!(commands, arg_list)

          ended_at = System.system_time(:millisecond)

          if target_fps != 0 do
            Process.sleep(Enum.max([target_frametime - (ended_at - started_at), 0]))
          end
        end
      )
    end
  end
end

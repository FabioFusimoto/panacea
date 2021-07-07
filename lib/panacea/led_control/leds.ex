defmodule Panacea.Leds do
  alias Panacea.Commands, as: Commands
  alias Panacea.Png, as: Png

  @dialyzer {:nowarn_function, [display_png: 1]}

  def show_leds() do
    Commands.write!("SHO")
  end

  def light_all(color) do
    Commands.write!("ALL", color)
  end

  def light_single(color, x, y) do
    Commands.write!("ONE",color |> List.insert_at(0, y) |> List.insert_at(0, x))
    :ok
  end

  def light_matrix(frame) do
    for y <- 0..(length(frame) - 1), x <- 0..(length(Enum.at(frame, y)) - 1) do
      color = Png.color_for(frame, x, y)
      light_single(color, x, y)
    end
    show_leds()
  end

  def display_png(filename) do
    frame = Png.read_image(filename)
    light_matrix(frame)
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
    target_frametime = round(1_000 / target_fps) # in miliseconds
    for _ <- 1..repetitions do
      Enum.each(
        Enum.zip(shifted_frames, pixel_diff),
        fn {frame, diff} ->
          started_at = System.system_time(:millisecond)

          commands = for _ <- 1..length(diff) do "ONE" end
          |> List.insert_at(length(diff), "SHO")

          arg_list = diff
          |> Enum.map(fn {x, y} -> [x, y] ++ Png.color_for(frame, x, y) end)
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

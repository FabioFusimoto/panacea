defmodule PanaceaWeb.PngLive do
  use PanaceaWeb, :live_view
  alias Panacea.Worker, as: Worker

  @dialyzer {:nowarn_function, [handle_event: 3]}

  def mount(_params, _assigns, socket) do
    {:ok, socket}
  end

  def handle_event(
    "display_png",
    %{"display_png" => %{"image_path" => path, "x_offset" => x_offset, "y_offset" => y_offset}},
    socket
  ) do
    offset = {String.to_integer(x_offset), String.to_integer(y_offset)}
    Worker.execute(fn -> Panacea.Leds.display_png(path, offset) end)
    {:noreply, put_flash(socket, :info, "Image #{path} in being displayed")}
  end

  def handle_event(
    "display_gif",
    %{
      "display_gif" => %{
        "gif_path" => path,
        "target_fps" => fps,
        "repetitions" => repetitions
      }
    },
    socket
  ) do
    Worker.execute(fn -> Panacea.Leds.display_gif(path, String.to_integer(fps), String.to_integer(repetitions)) end)
    {:noreply, put_flash(socket, :info, "GIF #{path} is being displayed")}
  end
end

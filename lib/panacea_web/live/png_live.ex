defmodule PanaceaWeb.PngLive do
  use PanaceaWeb, :live_view

  @dialyzer {:nowarn_function, [handle_event: 3]}

  def mount(_params, _assigns, socket) do
    {:ok, socket}
  end

  def handle_event("display_png", %{"image_selection" => %{"image_path" => path}}, socket) do
    Panacea.Leds.display_png(path)
    {:noreply, put_flash(socket, :info, "Image #{path} was displayed")}
  end

  def handle_event(
    "display_gif",
    %{"gif_selection" =>
      %{"gif_path" => path,
        "target_fps" => fps,
        "repetitions" => repetitions}},
    socket) do
    Panacea.Leds.display_gif(path, String.to_integer(fps), String.to_integer(repetitions))
    {:noreply, put_flash(socket, :info, "GIF #{path} was displayed")}
  end
end

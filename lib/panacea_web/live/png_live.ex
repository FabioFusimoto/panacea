defmodule PanaceaWeb.PngLive do
  use Surface.LiveView

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.NumberInput
  alias Surface.Components.Form.Submit
  alias Surface.Components.Form.TextInput

  alias Panacea.Worker, as: Worker

  @dialyzer {:nowarn_function, [handle_event: 3]}

  def render(assigns) do
    ~F"""
    <section class="container">
        <h2>PNG Utils</h2>

        <Form for={:display_png} submit="display_png">
            <Field name="image_path">
                <Label>Image</Label>
                <TextInput name="image_path"/>
            </Field>

            <div class="inline-element">
                <Field name="x_offset">
                    <Label>X Offset</Label>
                    <NumberInput name="x_offset" value={0}/>
                </Field>
            </div>

            <div class="inline-element">
                <Field name="y_offset">
                    <Label>Y Offset</Label>
                    <NumberInput name="y_offset" value={0}/>
                </Field>
            </div>
            <Submit>Display PNG</Submit>
        </Form>

        <Form for={:display_gif} submit="display_gif">
            <Field name="gif_path">
                <Label>GIF Path</Label>
                <TextInput name="gif_path"/>
            </Field>

            <div class="inline-element">
                <Field name="target_fps">
                    <Label>Target FPS</Label>
                    <NumberInput name="target_fps" value={8}/>
                </Field>
            </div>

            <div class="inline-element">
                <Field name="repetitions">
                    <Label>Repetitions</Label>
                    <NumberInput name="repetitions" value={4}/>
                </Field>
            </div>
            <Submit>Display GIF</Submit>
        </Form>
    </section>
    """
  end

  def mount(_params, _assigns, socket) do
    {:ok, socket}
  end

  def handle_event(
    "display_png",
    %{"image_path" => path, "x_offset" => x_offset, "y_offset" => y_offset},
    socket
  ) do
    offset = {String.to_integer(x_offset), String.to_integer(y_offset)}
    Worker.execute(fn -> Panacea.Leds.display_png(path, offset) end)
    {:noreply, put_flash(socket, :info, "Image #{path} in being displayed")}
   end

  def handle_event(
    "display_gif",
    %{
      "gif_path" => path,
      "target_fps" => fps,
      "repetitions" => repetitions
    },
    socket
  ) do
    Worker.execute(fn -> Panacea.Leds.display_gif(path, String.to_integer(fps), String.to_integer(repetitions)) end)
    {:noreply, put_flash(socket, :info, "GIF #{path} is being displayed")}
  end
end

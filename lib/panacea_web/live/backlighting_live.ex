defmodule PanaceaWeb.BacklightingLive do
  use Surface.LiveView

  alias Surface.Components.Form
  alias Surface.Components.Form.ColorInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Submit

  alias Panacea.Backlighting

  def render(assigns) do
    ~F"""
    <section class="container">
        <h2>Controls for Backlighting LEDs</h2>

        <Form for={:display_gradient} submit="display_gradient">
            <div class="inline-element">
                <Field name="starting_color">
                    <Label>Starting color</Label>
                    <ColorInput value="#0000FF"/>
                </Field>
            </div>
            <div class="inline-element">
                <Field name="ending_color">
                    <Label>Ending color</Label>
                    <ColorInput value="#FF0000"/>
                </Field>
            </div>
            <div class="inline-element">
                <Submit>Display gradient</Submit>
            </div>
        </Form>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event(
        "display_gradient",
        %{
          "display_gradient" => %{
            "starting_color" => starting_color,
            "ending_color" => ending_color
          }
        },
        socket
      ) do
    Backlighting.display_gradient(ending_color, starting_color)
    {:noreply, socket}
  end
end

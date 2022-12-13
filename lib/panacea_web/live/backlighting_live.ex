defmodule PanaceaWeb.BacklightingLive do
  use Surface.LiveView

  alias Surface.Components.Form
  alias Surface.Components.Form.ColorInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Submit

  alias Panacea.Backlighting
  alias Panacea.BacklightingServer

  def render(assigns) do
    ~F"""
    <section class="container">
        <h2>Controls for Backlighting LEDs</h2>

        <Form for={:toggle_display_matching_color} submit="toggle_display_matching_color">
            <div class="inline-element">
                <Submit>
                    {#if !@displaying_matching_color?}
                        Start displaying matching color
                    {#else}
                        Stop displaying matching color
                    {/if}
                </Submit>
            </div>
        </Form>

        <div hidden={@displaying_matching_color?}>
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
        </div>

    </section>
    """
  end

  def mount(_params, _session, socket) do
    BacklightingServer.stop()
    {
      :ok,
      assign(socket, displaying_matching_color?: false)
    }
  end

  def unmount() do
    BacklightingServer.stop()
    :ok
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

  def handle_event("toggle_display_matching_color", _, socket) do
    displaying_maching_color? = socket.assigns.displaying_matching_color?
    if !displaying_maching_color? do
      BacklightingServer.start()
    else
      BacklightingServer.stop()
    end

    {
      :noreply,
      assign(socket, displaying_matching_color?: !displaying_maching_color?)
    }
  end
end

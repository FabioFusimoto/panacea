defmodule PanaceaWeb.ArduinoLive do
  use Surface.LiveView

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.NumberInput
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Submit

  alias Panacea.Worker, as: Worker

  def render(assigns) do
    ~F"""
    <section class="container">
        <h2>Send command</h2>
        <div>
            <Form for={:command_selected} change="command_selected">
                <Field name="command_selected">
                    <Label>
                        Pick a command
                    </Label>
                    <Select name="command" options={@command_labels} />
                </Field>
            </Form>

            <Form for={:submitted} submit="submitted">
                {#for arg <- @selected_args}
                    <div class="inline-element">
                        <Label>{arg}</Label>
                        <NumberInput name={arg} value="0" />
                    </div>
                {/for}
                <Submit>Send command</Submit>
            </Form>
        </div>
    </section>
    """
  end

  def mount(_params, _assigns, socket) do
    command_map = Panacea.Commands.list()
    command_labels = command_map |> Map.keys() |> Enum.sort()
    initial_command = Enum.at(command_labels, 0)
    initial_args = command_map[initial_command]
    {:ok,
     assign(
       socket,
       command_map: command_map,
       command_labels: command_labels,
       selected_command: initial_command,
       selected_args: initial_args
     )
    }
  end

  def handle_event("command_selected", %{"command" => command}, socket) do
    command_map = socket.assigns.command_map
    args = command_map[command]
    updated_socket = assign(
      socket,
      selected_command: command,
      selected_args: args
    )

    {:noreply, updated_socket}
  end

  def handle_event("submitted", form, socket) do
    %{
      selected_command: selected_command,
      selected_args: arg_labels
    } = socket.assigns

    arg_values = Enum.map(arg_labels, &(form[&1]))

    Worker.execute(
      fn ->
        Panacea.Commands.write!(selected_command, arg_values)
      end
    )

    {:noreply, socket}
  end
end

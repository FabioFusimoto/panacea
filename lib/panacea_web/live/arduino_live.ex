defmodule PanaceaWeb.ArduinoLive do
  use PanaceaWeb, :live_view
  alias Panacea.Worker, as: Worker

  def render(assigns) do
    ~H"""
    <h2>Send command</h2>
    <div>
        <.form let={f} for={:command_selected} phx_change="command_selected">
            <%= label(f, "Pick a command") %>
            <%= select(f, :command, @command_labels) %>
        </.form>
    </div>

    <%= if @selected_command do %>
        <div>
            <.form let={f} for={:submitted} phx_submit="submitted">
                <div style="display: none;">
                    <%= label(f, :command) %>
                    <%= text_input(f, :command, value: @selected_command) %>
                </div>
                <%= for arg <- @selected_args do %>
                    <div class="inline-element">
                        <%= label(f, arg) %>
                        <%= number_input(f, arg, value: 0) %>
                    </div>
                <% end %>

                <%= submit("Send command") %>

            </.form>
        </div>
    <% end %>
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

  def handle_event("command_selected", %{"command_selected" => %{"command" => command}}, socket) do
    command_map = socket.assigns.command_map
    args = command_map[command]
    updated_socket = assign(
      socket,
      selected_command: command,
      selected_args: args
    )

    {:noreply, updated_socket}
  end

  def handle_event("submitted", %{"submitted" => form}, socket) do
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

    updated_socket = put_flash(
      socket,
      :info,
      "Command #{selected_command} excecuted with args #{inspect(arg_values)}"
    )

    {:noreply, updated_socket}
  end
end

defmodule PanaceaWeb.ArduinoLive do
  use PanaceaWeb, :live_view
  alias Panacea.Worker, as: Worker

  @default_command "Select a command"

  defp available_commands(), do: Panacea.Commands.list()

  defp build_command_list() do
    available_commands()
    |> Map.keys()
    |> Enum.sort()
    |> List.insert_at(0, @default_command)
  end

  defp build_argument_list(command, form) do
    arg_labels = available_commands()[command]
    Enum.map(arg_labels, &(form[&1]))
  end

  def mount(_params, _assigns, socket) do
    {:ok, assign(socket, commands: build_command_list(), args: [], selected_command: "")}
  end

  def handle_event("command_selected", %{"command_selected" => %{"command" => command}}, socket) do
    args = available_commands()[command]
    updated_socket = socket
    |> assign(selected_command: command, args: args)
    |> clear_flash()

    {:noreply, updated_socket}
  end

  def handle_event("submitted", %{"submitted" => form}, socket) do
    command = form["command"]
    arg_list = build_argument_list(command, form)

    Worker.execute(fn -> Panacea.Commands.write!(command, arg_list) end)

    updated_socket = socket
    |> assign(commands: build_command_list(), args: [], selected_command: "")
    |> put_flash(:info, "Command #{command} excecuted with args #{inspect(arg_list)}")
    {:noreply, updated_socket}
  end
end

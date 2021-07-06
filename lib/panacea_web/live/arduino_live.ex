defmodule PanaceaWeb.ArduinoLive do
  use PanaceaWeb, :live_view

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

  def handle_event("command_selected", %{"command_selection" => %{"command" => command}}, socket) do
    args = available_commands()[command]
    {:noreply, assign(socket, selected_command: command, args: args)}
  end

  def handle_event("submitted", %{"submit" => form}, socket) do
    command = form["command"]
    arg_list = build_argument_list(command, form)

    Panacea.Commands.write!(command, arg_list)

    {:noreply, assign(socket, commands: build_command_list(), args: [], selected_command: "")}
  end
end

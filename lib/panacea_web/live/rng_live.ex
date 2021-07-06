defmodule PanaceaWeb.RngLive do
  use PanaceaWeb, :live_view

  defp random_number(min \\ 1, max \\ 10), do: Enum.random(min..max)

  def mount(_params, _assigns, socket) do
    {:ok, assign(socket, :number, random_number())}
  end

  def handle_event("generate_number", %{"form" => %{"min" => min, "max" => max}}, socket) do
    new_number = random_number(String.to_integer(min), String.to_integer(max))
    updated_socket = socket
    |> put_flash(:info, "New number generated: #{new_number}")
    |> assign(:number, new_number)
    {:noreply, updated_socket}
  end
end

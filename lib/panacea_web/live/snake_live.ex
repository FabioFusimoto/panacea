defmodule PanaceaWeb.SnakeLive do
  use PanaceaWeb, :live_view
  alias Panacea.Snake.Game, as: Game

  def mount(_params, _assigns, socket) do
    {:ok, assign(socket, started: false)}
  end

  def handle_event("start_game", _value, socket) do
    Game.start()
    {:noreply, assign(socket, started: true)}
  end

  def handle_event("stop_game", _value, socket) do
    Game.stop()
    {:noreply, assign(socket, started: false)}
  end
end

defmodule PanaceaWeb.SnakeLive do
  use Surface.LiveView

  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  alias Panacea.Snake.Game, as: Game
  alias Panacea.Snake.Controls, as: Controls
  alias Phoenix.PubSub

  @height 18
  @width 18
  @topic "snake"

  def render(assigns) do
    ~F"""
    <section class="container">
        <h2>Snake</h2>

        {#if !@started}

        <Form for={:start_game} submit="start_game">
            <Submit>Start!</Submit>
        </Form>

        {#else}

            <Form for={:stop_game} submit="stop_game">
                <Submit>Stop!</Submit>
            </Form>
            <table id="game" class="game-window" phx-window-keydown="handle_key">
                <tr/>
                {#for x <- 0..(@height - 1)}
                    <tr>
                        {#for y <- 0..(@width - 1)}
                            {#case Enum.at(@cells_content, y) |> Enum.at(x)}
                                {#match "snake"}
                                    <td class="snake-cell"/>
                                {#match "apple"}
                                    <td class="apple-cell"/>
                                {#match "empty"}
                                    <td class="empty-cell"/>
                            {/case}
                        {/for}
                    </tr>
                {/for}
            </table>

        {/if}
    </section>
    """
  end

  def mount(_params, _assigns, socket) do
    PubSub.subscribe(Panacea.PubSub, @topic)

    initial_cells_content = for _ <- 0..(@height - 1) do
      for _ <- 0..(@width - 1) do
        "empty"
      end
    end

    {
      :ok,
      assign(
        socket,
        started: false,
        cells_content: initial_cells_content,
        width: @width,
        height: @height
      )
    }
  end

  def handle_event("start_game", _value, socket) do
    Game.start()
    {:noreply, assign(socket, started: true)}
  end

  def handle_event("stop_game", _value, socket) do
    Game.stop()
    {:noreply, assign(socket, started: false)}
  end

  def handle_event("handle_key", %{"key" => key}, socket) do
    case key do
      k when k in ["w", "W"] ->
        Controls.up()
      k when k in ["s", "S"] ->
        Controls.down()
      k when k in ["a", "A"] ->
        Controls.left()
      k when k in ["d", "D"] ->
        Controls.right()
      _ ->
        nil
    end

    {:noreply, socket}
  end

  def handle_info(%{topic: @topic, payload: payload}, socket) do
    %{snake_positions: snake_positions, apple_position: apple_position} = payload

    cells_content = for x <- 0..(@height - 1) do
      for y <- 0..(@width - 1) do
        cell_content(
          x,
          y,
          snake_positions,
          apple_position
        )
      end
    end

    {:noreply, assign(socket, cells_content: cells_content)}
  end

  defp cell_content(x, y, snake_positions, apple_position) do
    cond do
      Enum.member?(snake_positions, {x, y}) ->
        "snake"
      {x, y} == apple_position ->
        "apple"
      true ->
        "empty"
    end
  end
end

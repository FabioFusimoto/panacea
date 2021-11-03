defmodule PanaceaWeb.SnakeLive do
  use Surface.LiveView

  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Submit

  alias Panacea.Snake.Game
  alias Panacea.Snake.Controls
  alias Panacea.Snake.Autopilot

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
                <div class="inline-element">
                    <Field name="speed">
                        <Label>Speed</Label>
                        <Select name="speed" options={@speeds}/>
                    </Field>
                </div>
                <div class="inline-element">
                    <Field name="autopilot">
                        <Label>Autopilot?</Label>
                        <Checkbox name="autopilot"/>
                    </Field>
                </div>
                <div class="inline-element">
                    <Field name="loop">
                        <Label>Loop?</Label>
                        <Checkbox name="loop"/>
                    </Field>
                </div>
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

    speeds = [
      [
        key: 1,
        value: 1000
      ],
      [
        key: 2,
        value: 150
      ],
      [
        key: 3,
        value: 100
      ],
      [
        key: 4,
        value: 75
      ],
      [
        key: 5,
        value: 50
      ],
    ]

    {
      :ok,
      assign(
        socket,
        started: false,
        speeds: speeds,
        cells_content: initial_cells_content,
        width: @width,
        height: @height
      )
    }
  end

  def handle_event("start_game", %{"speed" => speed, "autopilot" => autopilot, "loop" => loop}, socket) do
    autopilot? = autopilot == "true"
    loop? = loop == "true"

    speed_as_int = String.to_integer(speed)

    if autopilot? do
      Autopilot.start(%{loop?: loop?, speed: speed_as_int})
    end

    Game.start(String.to_integer(speed))
    {:noreply, assign(socket, started: true, autopilot?: autopilot?)}
  end

  def handle_event("stop_game", _value, socket) do
    if socket.assigns.autopilot? do
      Autopilot.stop()
    end

    Game.stop()
    {:noreply, assign(socket, started: false)}
  end

  def handle_event("handle_key", %{"key" => key}, socket) do
    if !socket.assigns.autopilot? do
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
    end

    {:noreply, socket}
  end

  def handle_info(
    %{
      topic: @topic,
      payload: %{
        snake_positions: snake_positions,
        apple_position: apple_position
      }
    },
    socket
  ) do

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

  def handle_info(
    %{
      topic: @topic,
      payload: %{
        collided?: collided?,
        score: score
      }
    },
    socket
  ) do

    if collided? do
      IO.puts("\nFinal score: #{score}")
    end

    {:noreply, socket}
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

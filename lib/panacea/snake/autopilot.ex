defmodule Panacea.Snake.Autopilot do
  use GenServer
  alias Phoenix.PubSub

  alias Panacea.Snake.Controls
  alias Panacea.Snake.Game

  @topic "snake"
  @width 32
  @height 32

  #############
  # Interface #
  #############
  def start(init_params) do
    GenServer.start(__MODULE__, init_params, name: __MODULE__)
  end

  def stop() do
    if Process.whereis(__MODULE__) do

      GenServer.stop(__MODULE__)
    end
  end

  def init(init_params) do
    PubSub.subscribe(Panacea.PubSub, @topic)
    {:ok, Map.put(init_params, :restart_count, 0)}
  end

  ############
  # Handlers #
  ############
  def handle_info(
    %{
      topic: @topic,
      payload: %{
        snake_positions: snake_positions,
        apple_position: apple_position
      }
    },
    state
  ) do

    possible_next_positions = empty_surroundings(snake_positions)

    if length(possible_next_positions) > 0 do
      directions_and_costs = Enum.map(
        possible_next_positions,
        fn {direction, coordinates} ->
          cost = manhattan_distance(coordinates, apple_position)
          {direction, cost}
        end
      )

      lower_cost_direction =
        directions_and_costs
        |> Enum.min(fn ({_, cost_a}, {_, cost_b}) -> cost_a <= cost_b end)
        |> elem(0)

      case lower_cost_direction do
        "UP" ->
          Controls.up()
        "DOWN" ->
          Controls.down()
        "LEFT" ->
          Controls.left()
        "RIGHT" ->
          Controls.right()
        _ ->
          nil
      end
    end

    {:noreply, state}
  end

  def handle_info(
    %{
      topic: @topic,
      payload: %{
        collided?: collided?
      }
    },
    state
  ) do

    if collided? and state.loop? do
      Process.send_after(self(), :restart_game, 10000)
    end

    {:noreply, state}
  end

  def handle_info(:restart_game, state) do
    IO.puts("Restarting game...")

    Game.stop()
    Process.sleep(2000)
    Game.start(state.speed)

    IO.puts("Game restarted! - Restarts so far: #{state.restart_count}")

    {:noreply, Map.put(state, :restart_count, (state.restart_count + 1))}
  end

  ###########
  # Helpers #
  ###########
  defp empty_surroundings(snake) do
    head = Enum.at(snake, 0)
    head
    |> surroundings()
    |> Enum.filter(fn {_, coordinates} -> coordinates not in snake end)
  end

  defp surroundings({x, y}) do
    up = {x, if y - 1 > 0 do y - 1 else (@height - 1) end}
    down = {x, if y + 1 != @height do y + 1 else 0 end}
    right = {if x + 1 != @width do x + 1 else 0 end, y}
    left = {if x - 1 > 0 do x - 1 else (@width - 1) end, y}

    [{"UP", up}, {"DOWN", down}, {"RIGHT", right}, {"LEFT", left}]
  end

  defp manhattan_distance({x_current, y_current}, {x_goal, y_goal}) do
    x_distance = min(abs(x_current - x_goal), @width - abs(x_current - x_goal))
    y_distance = min(abs(y_current - y_goal), @height - abs(y_current - y_goal))
    x_distance + y_distance
  end
end

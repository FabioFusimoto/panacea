defmodule Panacea.Snake.Game do
  use GenServer

  alias Panacea.Leds, as: Leds
  alias Panacea.Worker, as: Worker

  # Game related attributes
  @background_color [0, 0, 0]
  @snake_color [0, 255, 0]
  @width 18
  @height 18
  @animation_time 750 # in ms

  #############
  # Interface #
  #############

  def start() do
    if ongoing_game() do
      GenServer.stop(__MODULE__)
    end

    Worker.reset_if_running()
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def stop() do
    if ongoing_game() do
      GenServer.stop(__MODULE__)
    end
  end

  def init(_) do
    initial_state = %{
      positions: [{5, 0}, {4, 0}, {3, 0}, {2, 0}, {1, 0}, {0, 0}],
      current_direction: "RIGHT",
      next_direction: "RIGHT",
      over?: false
    }

    Worker.execute(
      fn ->
        Leds.light_all(@background_color)
        Enum.each(initial_state.positions, fn {x, y} -> Leds.light_single(@snake_color, x, y)  end)
        Leds.show_leds()
      end
    )

    {:ok, initial_state}
  end

  def get_current_direction() do
    GenServer.call(__MODULE__, {:current_direction})
  end

  def set_next_direction(next_direction) do
    GenServer.cast(__MODULE__, {:set_next_direction, next_direction})
  end

  def update() do
    GenServer.cast(__MODULE__, {:update_game})
  end

  ############
  # Handlers #
  ############

  def handle_call({:current_direction}, _, state), do: {:reply, state.current_direction, state}

  def handle_cast({:set_next_direction, next_direction}, state) do
    valid_next_directions = %{
      "UP" => ["RIGHT", "LEFT"],
      "DOWN" => ["RIGHT", "LEFT"],
      "LEFT" => ["UP", "DOWN"],
      "RIGHT" => ["UP", "DOWN"]
    }

    if next_direction in valid_next_directions[state.current_direction] do
      {:noreply, %{state | next_direction: next_direction}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:game_over}, state) do
    Worker.reset_if_running()
    for _<- 1..3 do
      display_game_over_animation(state.positions)
    end
    {:noreply, state}
  end

  def handle_cast({:update_game}, state) do

    %{
      positions: positions,
      next_direction: next_direction,
      over?: over?
    } = state

    if !over? do
      new_positions = compute_new_positions(positions, next_direction)

      collided? = check_for_collision(
          Enum.at(new_positions, 0),
          List.delete_at(new_positions, 0)
      )

      if collided? do
        Task.start(
          fn -> GenServer.cast(__MODULE__, {:game_over}) end
        )
        {:noreply, %{state | over?: true}}
      else
        {new_head_x, new_head_y} = Enum.at(new_positions, 0)
        {previous_tail_x, previous_tail_y} = Enum.at(positions, length(positions) - 1)

        Worker.execute(
          fn ->
            if {previous_tail_x, previous_tail_y} != {new_head_x, new_head_y} do
              Leds.light_single(@background_color, previous_tail_x, previous_tail_y)
              Leds.light_single(@snake_color, new_head_x, new_head_y)
              Leds.show_leds()
            end
          end
        )

        {:noreply, %{state | positions: new_positions, current_direction: next_direction}}
      end
    end
  end

  ###########
  # Helpers #
  ###########

  defp ongoing_game, do: Process.whereis(__MODULE__)

  defp check_for_collision(head, positions_except_head), do: head in positions_except_head

  defp compute_new_positions(positions, new_direction) do
    {x_head, y_head} = Enum.at(positions, 0)
    snake_length = length(positions)

    case new_direction do
      "RIGHT" ->
        new_x_head = if x_head == (@width - 1) do
            0
          else
            x_head + 1
          end

        positions
        |> List.insert_at(0, {new_x_head, y_head})
        |> List.delete_at(snake_length)

      "LEFT" ->
        new_x_head = if x_head == 0 do
            @width - 1
          else
            x_head - 1
          end

        positions
        |> List.insert_at(0, {new_x_head, y_head})
        |> List.delete_at(snake_length)

      "DOWN" ->
        new_y_head = if y_head == (@height - 1) do
            0
          else
            y_head + 1
          end

        positions
        |> List.insert_at(0, {x_head, new_y_head})
        |> List.delete_at(snake_length)

      "UP" ->
        new_y_head = if y_head == 0 do
            @height - 1
          else
            y_head - 1
          end

          positions
          |> List.insert_at(0, {x_head, new_y_head})
          |> List.delete_at(snake_length)

      _ ->  positions
    end
  end

  defp display_game_over_animation(final_positions) do
    Worker.execute(
      fn ->
        Leds.light_all(@background_color)
        Process.sleep(@animation_time)
        Enum.each(final_positions, fn {x, y} -> Leds.light_single(@snake_color, x, y)  end)
        Leds.show_leds()
        Process.sleep(@animation_time)
      end
    )
    Process.sleep(2 * @animation_time)
  end
 end

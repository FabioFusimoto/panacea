defmodule Panacea.Snake.Game do
  use GenServer

  alias Panacea.Leds
  alias Panacea.Commands
  alias Panacea.Worker

  alias Phoenix.PubSub

  ###########################
  # Game related attributes #
  ###########################
  @background_color [0, 0, 0]
  @snake_color [0, 255, 0]
  @apple_color [255, 0, 0]
  @width 32
  @height 32
  @default_game_timeout 125
  @animation_time 600 # in ms

  ###########
  # Helpers #
  ###########
  @score_png "./resources/images/Score.png"
  @digits_path "./resources/images/digits/"
  @topic "snake"

  #############
  # Interface #
  #############
  def start() do
    start(@default_game_timeout)
  end

  def start(timeout) do
    stop()
    Worker.reset_if_running()
    GenServer.start(__MODULE__, timeout, name: __MODULE__)
  end

  def stop() do
    if ongoing_game() do
      GenServer.stop(__MODULE__)
    end
  end

  def get_current_direction() do
    GenServer.call(__MODULE__, {:current_direction})
  end

  def set_next_direction(next_direction) do
    GenServer.cast(__MODULE__, {:set_next_direction, next_direction})
  end

  def init(timeout) do
    initial_positions = [{3, 0}, {2, 0}, {1, 0}, {0, 0}]

    initial_state = %{
      positions: initial_positions,
      apple: generate_apple_position(initial_positions),
      ate_apple_on_last_move?: false,
      current_direction: "RIGHT",
      next_direction: "RIGHT",
      timeout: timeout,
      score: 0,
      over?: false
    }

    Worker.execute(
      fn ->
        set_background_commands = ["ALL"]
        set_background_args = [@background_color]

        light_snake_positions_commands = Enum.map(initial_state.positions, fn _ -> "ONE" end)
        light_snake_positions_args = Enum.map(
          initial_state.positions,
          fn {x, y} ->
            @snake_color |> List.insert_at(0, y) |> List.insert_at(0, x)
          end
        )

        light_apple_position_commands = ["ONE"]
        light_apple_position_args = [
          @apple_color
          |> List.insert_at(0, elem(initial_state.apple, 1))
          |> List.insert_at(0, elem(initial_state.apple, 0))
        ]

        show_leds_commands = ["SHO"]
        show_leds_args = [[]]

        command_list = set_background_commands ++ light_snake_positions_commands ++ light_apple_position_commands ++ show_leds_commands
        arg_list = set_background_args ++ light_snake_positions_args ++ light_apple_position_args ++ show_leds_args

        Commands.write_multiple!(command_list, arg_list)
      end
    )

    # Automatically update its state in a loop
    loop(timeout)

    {:ok, initial_state}
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

    display_score(state.score)

    {:noreply, state}
  end

  def handle_info(:update_game, state) do
    %{
      positions: positions,
      apple: apple,
      next_direction: next_direction,
      ate_apple_on_last_move?: ate_apple_on_last_move?,
      score: score,
      timeout: timeout,
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

        PubSub.broadcast(
          Panacea.PubSub,
          @topic,
          %{
            topic: @topic,
            payload: %{
              collided?: true,
              score: score
            }
          }
        )

        {:noreply, %{state | over?: true}}
      else
        new_positions = if ate_apple_on_last_move? do
          List.insert_at(new_positions, -1, Enum.at(positions, -1))
        else
          new_positions
        end

        {new_head_x, new_head_y} = Enum.at(new_positions, 0)
        {previous_tail_x, previous_tail_y} = Enum.at(positions, -1)

        ate_apple_on_this_move? = apple == Enum.at(new_positions, 0)
        {new_apple, new_score} = if ate_apple_on_this_move? do
          {generate_apple_position(new_positions), score + 1}
        else
          {apple, score}
        end

        Worker.execute(
          fn ->
            ate_apple_commands = ["ONE"]
            ate_apple_args = [
              @apple_color
              |> List.insert_at(0, elem(new_apple, 1))
              |> List.insert_at(0, elem(new_apple, 0))
            ]

            did_not_eat_apple_commands = ["ONE"]
            did_not_eat_apple_args = [
              @background_color
              |> List.insert_at(0, previous_tail_y)
              |> List.insert_at(0, previous_tail_x)
            ]

            {apple_related_commands, apple_related_args} = if ate_apple_on_last_move? do
              {ate_apple_commands, ate_apple_args}
            else
              {did_not_eat_apple_commands, did_not_eat_apple_args}
            end

            light_snake_head_commands = ["ONE"]
            light_snake_head_args = [
              @snake_color
              |> List.insert_at(0, new_head_y)
              |> List.insert_at(0, new_head_x)
            ]

            show_leds_commands = ["SHO"]
            show_leds_args = [[]]

            command_list = apple_related_commands ++ light_snake_head_commands ++ show_leds_commands
            arg_list = apple_related_args ++ light_snake_head_args ++ show_leds_args

            Commands.write_multiple!(command_list, arg_list)
          end
        )

        new_state = %{
          state |
          positions: new_positions,
          current_direction: next_direction,
          apple: new_apple,
          ate_apple_on_last_move?: ate_apple_on_this_move?,
          score: new_score
        }

        loop(timeout)

        PubSub.broadcast(
          Panacea.PubSub,
          @topic,
          %{
            topic: @topic,
            payload: %{
              snake_positions: new_positions,
              apple_position: new_apple
            }
          }
        )

        {:noreply, new_state}
      end
    end
  end

  ###########
  # Helpers #
  ###########
  defp ongoing_game(), do: Process.whereis(__MODULE__)

  defp loop(timeout), do: Process.send_after(self(), :update_game, timeout)

  defp generate_apple_position(snake_positions) do
    MapSet.new(for x <- 0..(@width - 1), y <- 0..(@height - 1) do {x, y} end)
    |> MapSet.difference(MapSet.new(snake_positions))
    |> Enum.random
  end

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

  defp display_score(score) do
    digits = Integer.digits(score)
    digit_count = length(digits)

    digits_display = digits
    |> Enum.with_index(fn digit, index -> {index, digit} end)
    |> Enum.map(fn {index, digit} ->
      png_file = "#{@digits_path}#{digit}.png"
      index_from_last = digit_count - 1 - index
      x_offset =
        case index_from_last do
          0 -> 13
          1 -> 8
          2 -> 3
        end
      {png_file, {x_offset, 9}}
    end)

    Worker.execute(
      fn ->
        Leds.light_all(@background_color)
        Leds.display_png(@score_png)
        Enum.each(digits_display, fn {file, offset} -> Leds.display_png(file, offset) end)
      end
    )
  end
 end

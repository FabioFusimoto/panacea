defmodule Panacea.Snake.Game do
  alias Panacea.Leds, as: Leds
  alias Panacea.Worker, as: Worker

  # Game related attributes
  @background_color [0, 0, 0]
  @snake_color [0, 255, 0]
  @timeout 150 # in milliseconds
  @width 18
  @height 18
  @animation_time 750 #in millis

  # The 'positions' array assumes the head is the first element
  @initial_state %{
    positions: [{5, 0}, {4, 0}, {3, 0}, {2, 0}, {1, 0}, {0, 0}],
    direction: "RIGHT",
    next_direction: "RIGHT",
    stop: false
  }

  # :snake agent will hold the game's state
  @agent :snake

  def agent(), do: @agent

  def width(), do: @width

  def height(), do: @height

  def start() do
    Agent.start_link(fn -> @initial_state end, name: @agent)
    Worker.execute(
      fn ->
        Leds.light_all(@background_color)
        Enum.each(@initial_state[:positions], fn {x, y} -> Leds.light_single(@snake_color, x, y)  end)
        Leds.show_leds()
        Task.start(fn -> update() end)
      end
    )
  end

  def stop() do
    Agent.stop(@agent)
    Worker.execute(&Worker.reset_if_running/0)
  end

  def stopped?() do
    ongoing_process = Process.whereis(@agent)
    if ongoing_process do
      Agent.get(@agent, fn %{stop: stop} -> stop end)
    else
      true
    end
  end

  defp check_for_collision(head, positions_except_head), do: head in positions_except_head

  defp display_game_over_animation(final_positions) do
    if (!stopped?()) do
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
      display_game_over_animation(final_positions)
    end
  end

  defp game_over(final_positions) do
    display_game_over_animation(final_positions)
  end

  def update() do
    if !stopped?() do
      Process.sleep(@timeout)

      if Process.whereis(@agent) do
        %{:positions => positions, :next_direction => next_direction} = Agent.get(@agent, fn state -> state end)

        new_positions = compute_new_positions(positions, next_direction)

        collided? = check_for_collision(
          Enum.at(new_positions, 0),
          List.delete_at(new_positions, 0)
        )

        if collided? do
          game_over(positions)
        else
          Agent.update(@agent, fn state -> %{state | positions: new_positions, direction: next_direction} end)

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

          update()
        end
      end
    end
  end

  defp compute_new_positions(positions, direction) do
    {x_head, y_head} = Enum.at(positions, 0)
    snake_length = length(positions)

    case direction do
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
 end

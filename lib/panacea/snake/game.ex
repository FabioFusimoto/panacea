defmodule Panacea.Snake.Game do
  alias Panacea.Leds, as: Leds
  alias Panacea.Worker, as: Worker

  # Game related attributes
  @background_color [0, 0, 0]
  @snake_color [0, 255, 0]
  @timeout 200 # in miliseconds
  @width 18
  @height 18

  # The 'positions' array assumes the head is the first element
  @initial_state %{positions: [{2, 0}, {1, 0}, {0, 0}], direction: "RIGHT", stop: false}

  # :snake agent will hold the game's state
  @agent :snake

  def start() do
    Agent.start_link(fn -> @initial_state end, name: @agent)
    Worker.execute(
      fn ->
        Leds.light_all(@background_color)
        Enum.each(@initial_state[:positions], fn {x, y} -> Leds.light_single(@snake_color, x, y) end)
        Leds.show_leds()
        Task.start(fn -> update() end)
      end
    )
  end

  def stop() do
    Agent.stop(@agent)
    Worker.execute(&Worker.reset_if_running/0)
  end

  def stopped?(), do: Agent.get(@agent, fn %{stop: stop} -> stop end)

  def update() do
    if !stopped?() do
      Process.sleep(@timeout)

      if Process.whereis(@agent) do
        %{:positions => positions, :direction => direction} = Agent.get(@agent, fn state -> state end)

        {changed?, new_positions} = compute_new_positions(positions, direction)

        if changed? do
          Agent.update(@agent, fn state -> %{state | positions: new_positions} end)
          {new_head_x, new_head_y} = Enum.at(new_positions, 0)
          {previous_tail_x, previous_tail_y} = Enum.at(positions, length(positions) - 1)
          Worker.execute(
            fn ->
              Leds.light_single(@snake_color, new_head_x, new_head_y)
              Leds.light_single(@background_color, previous_tail_x, previous_tail_y)
              Leds.show_leds()
            end
          )
        end

        update()
      end
    end
  end

  defp compute_new_positions(positions, direction) do
    {x_head, y_head} = Enum.at(positions, 0)
    snake_length = length(positions)

    case direction do
      "RIGHT" ->
        if x_head == (@width - 1) do
          {false, positions}
        else
          new_positions = positions
          |> List.insert_at(0, {x_head + 1, y_head})
          |> List.delete_at(snake_length)
          {true, new_positions}
        end
      "LEFT" ->
        if x_head == 0 do
          {false, positions}
        else
          new_positions = positions
          |> List.insert_at(0, {x_head - 1, y_head})
          |> List.delete_at(snake_length)
          {true, new_positions}
        end
      "UP" ->
        if y_head == (@height - 1) do
          {false, positions}
        else
          new_positions = positions
          |> List.insert_at(0, {x_head, y_head + 1})
          |> List.delete_at(snake_length)
          {true, new_positions}
        end
      "DOWN" ->
        if y_head == 0 do
          {false, positions}
        else
          new_positions = positions
          |> List.insert_at(0, {x_head, y_head - 1})
          |> List.delete_at(snake_length)
          {true, new_positions}
        end
      _ -> {false, positions}
    end
  end
 end

defmodule Panacea.Snake.Controls do
  alias Panacea.Snake.Game, as: Game

  defp current_direction(), do: Agent.get(Game.agent(), fn %{direction: direction} -> direction end)

  defp update_next_direction(new_direction) do
    Agent.update(Game.agent(), fn state -> %{state | next_direction: new_direction} end)
  end

  defp check_and_update_next_direction(new_direction, valid_previous_directions) do
    if current_direction() in valid_previous_directions do
      update_next_direction(new_direction)
    end
  end

  def up(), do: check_and_update_next_direction("UP", ["RIGHT", "LEFT"])

  def down(), do: check_and_update_next_direction("DOWN", ["RIGHT", "LEFT"])

  def left(), do: check_and_update_next_direction("LEFT", ["UP", "DOWN"])

  def right(), do: check_and_update_next_direction("RIGHT", ["UP", "DOWN"])
end
